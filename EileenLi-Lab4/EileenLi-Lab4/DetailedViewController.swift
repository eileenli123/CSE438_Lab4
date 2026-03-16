//
//  DetailedViewController.swift
//  EileenLi-Lab4
//
//  Created by Eileen Li on 3/6/26.
//

import UIKit

class DetailedViewController: UIViewController {

   // var image: UIImage!
    var movieName: String = ""
    var moviePoster: UIImage!
    var releaseDate: String = "unknown"
    var rating: Double = 0.0
    var ratingCount: Int = 0
    var overview: String = "unknown"
    
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var movieNameTitle: UINavigationItem!
    @IBOutlet weak var moviePosterImage: UIImageView!
    @IBOutlet weak var releaseDateLabel: UILabel!

    @IBOutlet weak var overviewLabel: UILabel!
    
    
    override func viewDidLoad() {
        
        let roundedRating = (rating * 10).rounded() / 10
        
        super.viewDidLoad()
        movieNameTitle.title = movieName
        moviePosterImage.image = moviePoster
        releaseDateLabel.text = releaseDate
        ratingLabel.text = "\(roundedRating)/10 (\(ratingCount) votes)"
        overviewLabel.text = overview
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
