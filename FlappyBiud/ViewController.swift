//
//  ViewController.swift
//  FlappyBiud
//
//  Created by 山本優也 on 2021/02/04.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //SKviewに型を変換する
        let skView = self.view as! SKView
        
        //FPSを表示する 画面が一秒間に何回更新されているかを表すFPS
        skView.showsFPS = true
        
        //ノードの数を表示する　ノード数が多いと処理が重たくなる  
        skView.showsNodeCount = true
        
        //ビューと同じサイズでシーンを作成する
        let scene = GameScen(size: skView.frame.size)
        
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }
    
    //ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

