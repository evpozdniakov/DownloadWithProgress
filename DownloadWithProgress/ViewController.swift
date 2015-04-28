//
//  ViewController.swift
//  DownloadWithProgress
//
//  Created by Evgeniy Pozdnyakov on 2015-04-25.
//  Copyright (c) 2015 Evgeniy Pozdnyakov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var fileAdownloadBtn: UIButton!
    @IBOutlet weak var fileBdownloadBtn: UIButton!
    @IBOutlet weak var fileAprogressLbl: UILabel!
    @IBOutlet weak var fileBprogressLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        fileAprogressLbl.hidden = true
        fileBprogressLbl.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fileAdownloadBtnClicked(sender: AnyObject) {
        fileAprogressLbl.text = "0%"
        fileAprogressLbl.hidden = false

        downloadFrom("http://goo.gl/oxlCUq", saveWithFileName: "A.mp3") { bytesDownloaded, bytesTotal in
            let progress = lroundf(Float(bytesDownloaded) / Float(bytesTotal) * 100)
            println("progress \(progress)")
            dispatch_async(dispatch_get_main_queue()) {
                self.fileAprogressLbl.text = "\(progress)%"
            }
        }
    }

    @IBAction func fileBdownloadBtnClicked(sender: AnyObject) {
        fileBprogressLbl.text = "0%"
        fileBprogressLbl.hidden = false

        downloadFrom("http://goo.gl/USz0AR", saveWithFileName: "B.mp3") { bytesDownloaded, bytesTotal in
            let progress = lroundf(Float(bytesDownloaded) / Float(bytesTotal) * 100)
            println("progress \(progress)")
            dispatch_async(dispatch_get_main_queue()) {
                self.fileBprogressLbl.text = "\(progress)%"
            }
        }
    }

    func downloadFrom(stringURL: String,  saveWithFileName fileName: String, progressHandler: ((Int64, Int64) -> Void)?) {
        let remoteURL = NSURL(string: stringURL) as NSURL!
        let fileManager = NSFileManager.defaultManager()
        let documentDirs = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)

        if documentDirs.count == 0 {
            println("Error: NSFileManager didn't find document directory")
            return
        }

        let documentDir = documentDirs[0] as! NSURL
        let localURL = documentDir.URLByAppendingPathComponent(fileName)

        println("will download file from: \(remoteURL) and save to: \(localURL)")

        Ajax.downloadFileFromUrl(remoteURL, saveTo: localURL, reportingProgress: progressHandler)
    }
}
