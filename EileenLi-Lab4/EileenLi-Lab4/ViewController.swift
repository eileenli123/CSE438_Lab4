//
//  ViewController.swift
//  EileenLi-Lab4
//
//  Created by Eileen Li on 3/4/26.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    //TODO: Some imahes are not correct -- i think if not image is found/fetched, it just keeps wtv is at the index previously -- set default image

    //MARK: - CODABLES
    struct Movie: Codable {
        let id: Int
        let title: String
        let overview: String
        let posterPath: String?
        let releaseDate: String?
        let rating: Double?
        let reviewCount: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case overview
            case posterPath = "poster_path"
            case releaseDate = "release_date"
            case rating = "vote_average"
            case reviewCount = "vote_count"
        }
    }
    

    struct MovieResponse: Codable {
        let results: [Movie]
    }
    

    //MARK: - LOCAL VARS
    let apiKey = Secrets.apiKey
    var displayedMovies = [Movie]() //arr to track the curr movies to be displayed
    var imageCache: [Int: UIImage] = [:] // cache images with movie id as key so it doesnt have to be refetched
    
    //MARK: - UI OUTLETS
    @IBOutlet weak var movieCollectionView: UICollectionView!
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var showingMoviesText: UILabel!
    
    @IBOutlet weak var movieGallerySpinner: UIActivityIndicatorView!
    
    
    //MARK: - FUNCTIONS
    func setMovieGallerySpinner(on state: Bool) {
        if state == true {
            self.movieGallerySpinner.isHidden = false
            self.movieGallerySpinner.startAnimating()
        } else {
            self.movieGallerySpinner.isHidden = true
            self.movieGallerySpinner.stopAnimating()
        }
    }
    
    func fetchTrendingData() {
        self.setMovieGallerySpinner(on: true)
        
        guard let url = URL(string: "https://api.themoviedb.org/3/trending/movie/week?api_key=\(apiKey)") else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  // 1 sec delay to test spinner -- TODO: comment out
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    
                    let data = try Data(contentsOf: url)
                    
                    let movieResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                    
                    self.displayedMovies = movieResponse.results
                    
                    //print for debug
                    for movie in self.displayedMovies {
                        print("ID: \(movie.id), Title: \(movie.title), Overview: \(movie.overview), Poster: \(movie.posterPath ?? "No poster")")
                    }
                    
                    // reload collection view when done fetching
                    DispatchQueue.main.async {
                        self.setMovieGallerySpinner(on: false)
                        self.cacheImages()
                        self.movieCollectionView.reloadData()
                    }
                } catch {
                    print("Error fetching or decoding data: \(error)")
                }
            }
        }

    }
    
    func fetchByKeyword(keyword: String) {
        self.setMovieGallerySpinner(on: true)
        
        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(keyword)&language=en-US") else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 1 sec delay to test spinner -- TODO: comment out
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    
                    let data = try Data(contentsOf: url)
                    
                    let movieResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                    
                    self.displayedMovies = movieResponse.results
                    
                    // reload collection view when done fetching
                    DispatchQueue.main.async {
                        self.setMovieGallerySpinner(on: false)
                        self.cacheImages() //cache images of new search
                        self.movieCollectionView.reloadData()
                    }
                } catch {
                    print("Error fetching or decoding data: \(error)")
                }
            }
        }
    
    }
    
    func cacheImages() {
        for movie in displayedMovies {
            //don't fetch if already cached
            if (imageCache[movie.id] != nil) { continue }
            
            guard let posterPath = movie.posterPath,
                  let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") else { return }
            
            // Fetch and cache image asynchronously
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    if let image = UIImage(data: data) {
                        // Cache the image for the movie id when image done fetching
                        DispatchQueue.main.async {
                            self.imageCache[movie.id] = image
                            self.movieCollectionView.reloadData()
                        }
                    }
                } catch {
                    print("Error fetching image for movie \(movie.id): \(error)")
                }
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search text changed to: \(searchText)")

        if searchText.isEmpty {
            // if search text is empty, show featured movies
            showingMoviesText.text = "Trending Movies"
            fetchTrendingData()
        } else {
            self.displayedMovies = [] //clear movies to show loading spinner
            self.movieCollectionView.reloadData()
            showingMoviesText.text = "Search Results for: \(searchText)"
            fetchByKeyword(keyword: searchText)
        }

        movieCollectionView.reloadData()
    }
    
    //MARK: - UI
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setMovieGallerySpinner(on: false)
        
        movieCollectionView.dataSource = self
        movieCollectionView.delegate = self
        movieSearchBar.delegate = self
        
        // create layout
        let layout = UICollectionViewFlowLayout()
        
        let width = (movieCollectionView.bounds.width - 20) / 3 // 3 items per row (with padding)
        let height: CGFloat = 175 // fixed height
        layout.itemSize = CGSize(width: width, height: height)
        layout.minimumInteritemSpacing = 10  // space between items
        layout.minimumLineSpacing = 10  // space between rows
        
        movieCollectionView.setCollectionViewLayout(layout, animated: true) //set layout
        
        self.fetchTrendingData()

    }
    
    //MOVIE COLLECTION VIEW
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 10
//    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath)
        let movie = displayedMovies[indexPath.row]
        
        //set the title label
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = movie.title
            titleLabel.textColor = .white
            titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        }
        
        //set image (should always be cached by design)
        if let cachedImage = imageCache[movie.id] {
            if let imageView = cell.viewWithTag(2) as? UIImageView {
                imageView.image = cachedImage
            }
        } else {
            // TODO: add placeholder image
//            if let imageView = cell.viewWithTag(2) as? UIImageView {
//                imageView.image = UIImage(named: "placeholder.png")
//            }
            // set the background color to gray as fallback for now
            cell.backgroundColor = .gray
        }
        
        
        return cell
    }
    
    
    
    //go into details about selected movie
    func collectionView( _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected movie: \(indexPath.row)")
        let selectedMovie = displayedMovies[indexPath.row]
        
        // instantiate DetailedViewController
        if let detailedVC = storyboard?.instantiateViewController(withIdentifier: "DetailedViewController") as? DetailedViewController {
            
            // pass the selected movie info
            detailedVC.movieName = selectedMovie.title
            detailedVC.moviePoster = imageCache[selectedMovie.id]
            detailedVC.releaseDate = selectedMovie.releaseDate ?? "unknown"
            detailedVC.rating = selectedMovie.rating ?? 0.0
            detailedVC.ratingCount = selectedMovie.reviewCount ?? 0
            detailedVC.overview = selectedMovie.overview
            
            
            // push the vc onto navigation stack
            navigationController?.pushViewController(detailedVC, animated: true)
        }
    }
    

}

