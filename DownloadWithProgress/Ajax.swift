//
//  Ajax.swift
//
//  Created by Evgeniy Pozdnyakov on 2015-04-25.
//  Copyright (c) 2015 Evgeniy Pozdnyakov. All rights reserved.
//

import Foundation

class Ajax: NSObject {
    var localURL: NSURL?
    var progressHandler: ((Int64, Int64) -> Void)?

    /**
        Creates NSURLSessionDataTask which sends http get request to url
        and passes the response to success handler

        **Warning:** The fail handler not implemented.

        Usage:

        Ajax.get(url: url, success: completionHandler)
        or
        Ajax.get(url: url) { data in <some code> }

        :param: url The url to send http request.
        :param: success The handler to perform (with response data as parameter) if server returns status 200.

        :returns: NSURLSessionDataTask
    */
    static func get(#url: NSURL, success: (data: NSData) -> ()) -> NSURLSessionDataTask {
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url) {data, response, error in
            if let error = error {
                if error.code == -999 { return } // task cancelled

                // The operation couldn’t be completed. (kCFErrorDomainCFNetwork error -1003.)
                // It happens when URL is unreachable
                println("ajax-error-task-cancelled: \(error)")
                return
            }

            let httpResponse = response as? NSHTTPURLResponse

            if httpResponse == nil || httpResponse!.statusCode == 500 {
                // Server didn't return any response
                // #FIXME: add optional faill handler and call it with error
                println("ajax-error-no-response")
                return
            }

            if httpResponse!.statusCode != 200 {
                // erver response code != 200
                // #FIXME: add optional faill handler and call it with error
                println("ajax-error-unexpected-response-code: \(httpResponse!.statusCode)")
                return
            }

            success(data: data)
        }

        dataTask.resume()

        return dataTask
    }

    /**
        Shorthand for Ajax.get(), but it proceeds only if was able to create url from string passed.

        **Warning:** The fail handler not implemented.

        Usage:

        Ajax.getJsonByUrlString("http://bumagi.net/ios/mds/?q=abc")

        :param: urlString
        :param: success The success handler.

        :returns: NSURLSessionDataTask?
    */
    static func getJsonByUrlString(urlString: String, success: (NSData) -> Void) -> NSURLSessionDataTask? {
        if let url = NSURL(string:urlString) {
            let dataTask = Ajax.get(url: url, success: success)

            return dataTask
        }
        else {
            // #FIXME: add fail handler and return error back
        }

        return nil
    }

    /**
        Transforms json passed in nsdata format into [AnyObject] array.

        **Warning:** The errors not handled.

        Usage:

        Ajax.parseJsonArray(data)

        :param: data JSON in NSData format.

        :returns: optional array [AnyObject].
    */
    static func parseJsonArray(data: NSData) -> [AnyObject]? {
        var error: NSError?

        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? [AnyObject] {
            return json
        }

        if let error = error {
            // Cocoa error 3840: JSON text did not start with array or object and option to allow fragments not set
            // #FIXME: handle the error
            println("data-model-error-1001: \(error)")
        }
        else {
            // Error: JSON could be parsed, but it can be casted to [AnyObject] format
            // #FIXME: handle the error
            println("data-model-error-1002")
        }

        return nil
    }

    /**
        Transforms json passed in nsdata format into [String: AnyObject] dictionary.

        **Warning:** The errors not handled.

        Usage:

        Ajax.parseJsonDictionary(data)

        :param: data JSON in NSData format

        :returns: [String: AnyObject]?
    */
    static func parseJsonDictionary(data: NSData) -> [String: AnyObject]? {
        var error: NSError?

        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? [String: AnyObject] {
            return json
        }

        if let error = error {
            // Cocoa error 3840: JSON text did not start with array or object and option to allow fragments not set
            // #FIXME: handle the error
            println("data-model-error-1003: \(error)")
        }
        else {
            // Error: JSON could be parsed, but it can be casted to [String: AnyObject] format
            // #FIXME: handle the error
            println("data-model-error-1004")
        }

        return nil
    }

    /**
        Will download file from remote and save it locally. It will call progress handler periodically while downloading. Works asyncronously.

        Usage:

            Ajax.downloadFileFromUrl(remoteURL, saveTo: localURL) { bytesDownloaded, bytesTotal in
                // display progress
            }

        :returns: NSURLSessionDownloadTask
    */
    static func downloadFileFromUrl(remoteURL: NSURL, saveTo localURL: NSURL, reportingProgress progressHandler: ((Int64, Int64) -> Void)?) -> NSURLSessionDownloadTask {
        let ajax = Ajax()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: ajax, delegateQueue: nil)
        let downloadTask = session.downloadTaskWithURL(remoteURL)

        ajax.localURL = localURL
        ajax.progressHandler = progressHandler

        downloadTask.resume()

        return downloadTask
    }
}

extension Ajax: NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        assert(localURL != nil)

        println("file saved at \(location)")

        let fileManager = NSFileManager.defaultManager()
        var error: NSError?

        fileManager.moveItemAtURL(location, toURL: localURL!, error: &error)

        if let error = error {
            println("error moving file: \(error)")
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let handler = progressHandler {
            handler(totalBytesWritten, totalBytesExpectedToWrite)
        }
    }
}