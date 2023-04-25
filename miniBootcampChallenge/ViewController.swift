//
//  ViewController.swift
//  miniBootcampChallenge
//

import UIKit

class ViewController: UICollectionViewController {
    
    private struct Constants {
        static let title = "Mini Bootcamp Challenge"
        static let cellID = "imageCell"
        static let cellSpacing: CGFloat = 1
        static let columns: CGFloat = 3
        static var cellSize: CGFloat?
    }
    
    private lazy var urls: [URL] = URLProvider.urls
    
    private let imageDownloadGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.title
        
        // Download images and reload collection view data when complete
        downloadImages(from: urls, viewController: self) { _ in
            self.collectionView.reloadData()
        }
    }
    
    
}


// TODO: 1.- Implement a function that allows the app downloading the images without freezing the UI or causing it to work unexpected way
// This private function downloads an image from the given URL and returns it in the completion handler.
// The completion handler takes an optional UIImage parameter, which may be nil if there was an error downloading or creating the image.
private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    
    // Create a data task to download the image from the given URL using URLSession; a native function to handle requests.
    URLSession.shared.dataTask(with: url) { data, response, error in
        
        // If there was an error, print a message to the console and call the completion handler with a nil parameter.
        if let error = error {
            print("Error downloading image: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        // If there is data returned, attempt to create a UIImage from it.
        guard let data = data, let image = UIImage(data: data) else {
            // If there is no data or the image could not be created from the data, print a message to the console and call the completion handler with a nil parameter.
            print("Unable to create image from data")
            completion(nil)
            return
        }
        
        // If the image was successfully created, call the completion handler with the image parameter.
        completion(image)
        
    }.resume() // Call the data task's resume() method to start the download.
}


// TODO: 2.- Implement a function that allows to fill the collection view only when all photos have been downloaded, adding an animation for waiting the completion of the task.
// This function downloads images from an array of URLs and returns an array of UIImage objects
private func downloadImages(from urls: [URL], viewController: UICollectionViewController, completion: @escaping ([UIImage]) -> Void) {
    // Create an empty array to store the downloaded images
    var images: [UIImage] = []
    // Create a dispatch group to keep track of the image downloads
    let imageDownloadGroup = DispatchGroup()
    
    // Create a UIActivityIndicatorView to show while images are downloading
    let activityIndicator = UIActivityIndicatorView(style: .large)
    activityIndicator.startAnimating()
    
    // Add the activity indicator to the center of the view controller's view
    activityIndicator.center = viewController.view.center
    viewController.view.addSubview(activityIndicator)
    
    // Loop through each URL and download the image
    for url in urls {
        // Notify the dispatch group that a new image download has started
        imageDownloadGroup.enter()
        // Call the downloadImage function to download the image from the URL
        downloadImage(from: url) { image in
            // If the image is not nil, append it to the images array
            if let image = image {
                images.append(image)
            }
            // Notify the dispatch group that the image download has completed
            imageDownloadGroup.leave()
        }
    }

    // Wait for all images to download before calling the completion closure
    imageDownloadGroup.notify(queue: .main) {
        // Hide the activity indicator once all images have downloaded
        activityIndicator.stopAnimating()
        
        completion(images)
    }
}

// MARK: - UICollectionView DataSource, Delegate
extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        urls.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Attempts to dequeue a reusable cell with the given identifier from the collection view's reusable cell pool, and casts it as an ImageCell object. If this fails, it returns a generic UICollectionViewCell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as? ImageCell else { return UICollectionViewCell() }
        
        // Gets the URL for the image corresponding to the current row of the collection view
        let url = urls[indexPath.row]
        // Clear any previous image
        cell.display(nil)
        
        //Asynchronously downloads the image from the URL and calls the closure when the download is complete, passing the downloaded image if successful
        downloadImage(from: url) { image in
            // When the download is complete, updates the UI by setting the downloaded image on the ImageCell using the display method, and ensuring that it runs on the main thread
            DispatchQueue.main.async {
                // Returns the ImageCell to be displayed in the current row of the collection view
                cell.display(image)
            }
        }
        // Returns the Downloaded Image to the ImageCell
        return cell
    }
    
}


// MARK: - UICollectionView FlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if Constants.cellSize == nil {
            let layout = collectionViewLayout as! UICollectionViewFlowLayout
            let emptySpace = layout.sectionInset.left + layout.sectionInset.right + (Constants.columns * Constants.cellSpacing - 1)
            Constants.cellSize = (view.frame.size.width - emptySpace) / Constants.columns
        }
        return CGSize(width: Constants.cellSize!, height: Constants.cellSize!)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }
}
