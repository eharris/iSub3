//
//  LyricsViewController.swift
//  iSub
//
//  Created by Benjamin Baron on 11/23/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

import UIKit
import SnapKit

final class LyricsViewController: UIViewController {
    private let dataModel = SUSLyricsDAO()
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 30)
        titleLabel.textAlignment = .center
        titleLabel.text = "Lyrics"
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(45)
            make.leading.trailing.top.equalToSuperview()
        }
        
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLyricsLabel()
        NotificationCenter.addObserverOnMainThread(self, selector: #selector(updateLyricsLabel), name: ISMSNotification_SongPlaybackStarted)
        NotificationCenter.addObserverOnMainThread(self, selector: #selector(updateLyricsLabel), name: ISMSNotification_LyricsDownloaded)
        NotificationCenter.addObserverOnMainThread(self, selector: #selector(updateLyricsLabel), name: ISMSNotification_LyricsFailed)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.removeObserverOnMainThread(self)
    }
    
    @objc private func updateLyricsLabel() {
        if let song = PlayQueue.shared().currentSong(), let lyrics = dataModel.lyrics(forArtist: song.artist, andTitle: song.title), lyrics.count > 0 {
            textView.text = lyrics
        } else {
            textView.text = "\n\nNo lyrics found"
        }
    }
}
