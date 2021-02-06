//
//  GameScen.swift
//  FlappyBiud
//
//  Created by 山本優也 on 2021/02/04.
//

import UIKit
import SpriteKit

class GameScen: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var featherNode:SKNode!
    
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0   //0...00001
    let groundCategory: UInt32 = 1 << 1 //0...00010
    let wallCategory: UInt32 = 1 << 2   //0...00100
    let scoreCategory: UInt32 = 1 << 3  //0...01000
    let itemCategory: UInt32 = 1 << 4   //0...1000
    
    //スコア用
    var score = 0
    //アイテム用
    var item = 0
    
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemLabelNode:SKLabelNode!
    
    let userDefaults:UserDefaults = UserDefaults.standard
    
   

    //SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を指定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード ゲームオーバーの時に止めるためのノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //BGM
        let music = SKAudioNode.init(fileNamed: "Lethe.mp3")
        self.addChild(music)
        
        //壁用ノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //羽根ノード
        featherNode = SKNode()
        scrollNode.addChild(featherNode)
        
        //各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupFeather()
        
        setupScoreLabel()
    }
    
    //画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restrat()
        }
        
        //効果音。
        let scoreSound = SKAction.playSoundFileNamed("キャンセル2.mp3", waitForCompletion: false)
        self.featherNode.run(scoreSound)
        
    
    }
    
    func setupScoreLabel() {
        score = 0
        item = 0
        
        //スコアラベル
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left//左詰めか右詰め
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        //ベストスコアラベル
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left//左詰めか右詰め
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        
        //アイテムスコアラベル
        itemLabelNode = SKLabelNode()
        itemLabelNode.fontColor = UIColor.black
        itemLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemLabelNode.zPosition = 100 // 一番手前
        itemLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left//左詰めか右詰め
        itemLabelNode.text = "Item Score:\(item)"
        self.addChild(itemLabelNode)
        
       
    }
    
    func setupGround() {
    
        //地面の画像を読み込む SKTextureが表示する画像のクラス
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算　+2で画面から見きれないようにしている
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像１枚分スクロールさせるアクション　５秒掛ける
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション　０秒で戻す
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロールー＞元の位置ー＞左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する　左下が原点、positionで指定するのは画像(＝Node)の中心位置
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突カテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないようにに設定する
            sprite.physicsBody?.isDynamic = false
            
            //シーンにスプライトを追加する
            scrollNode.addChild(sprite)
            
        }
        
    }
  
    func setupCloud() {
    
        //雲の画像を読み込む SKTextureが表示する画像のクラス
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算　+2で画面から見きれないようにしている
        let needNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像１枚分スクロールさせるアクション　５秒掛ける
        let moveGround = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション　０秒で戻す
        let resetGround = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロールー＞元の位置ー＞左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100//一番うしろになるようにする
            
            //スプライトの表示する位置を指定する　左下が原点、positionで指定するのは画像(＝Node)の中心位置
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //シーンにスプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupWall() {                                                                        //壁
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear//当たり判定のため画素優先の.linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
                    //鳥の画像サイズを取得
                    let birdSize = SKTexture(imageNamed: "bird_a").size()
                    
                    //鳥が通り抜ける時間の長さを取りサイズの3倍とする
                    let slit_length = birdSize.height * 3
                    
                    //隙間位置の上下の振れ幅を取りサイズの2.5倍とする
                    let random_y_range = birdSize.height * 2.5
                    
                    //下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
                    let groundSize = SKTexture(imageNamed: "ground").size()
                    let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
                    let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width, y: 0)
            wall.zPosition = -50 //雲より手前、地面より奥
            
            // 0~random_y_rangeまでランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁のスプライトを作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory //数字をつける
            
            //衝突の時に動かないようにに設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁のスプライトを作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory //数字をつける
            
            //衝突の時に動かないようにに設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.size.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成ｰ>時間待ちｰ>壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        //アクションを設定
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {                                                                                                             //鳥
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
    //羽根のアイテム
    func setupFeather() {
    
        //羽根の画像を読み込む SKTextureが表示する画像のクラス
        let featherTexture = SKTexture(imageNamed: "feather_red")
        featherTexture.filteringMode = .linear
        
       
       
        
        let createFeather = SKAction.run ({
            
            
            //縦のランダムな値
            let random = CGFloat.random(in: 0...300)
            let random_2 = CGFloat.random(in: -300...0)
            let random_3 = CGFloat.random(in: 0...100)
            let random_4 = CGFloat.random(in: -100...0)
    
            //画面外まで移動するアクションを作成
            let moveFeather = SKAction.moveBy(x: -self.frame.size.width - featherTexture.size().width, y: random + random_2, duration: 3.5)
             

            //乗せるスプライト
            let fe = SKSpriteNode(texture: featherTexture)
            
                fe.position = CGPoint(
                    x: self.frame.size.width,
                    y: self.frame.size.height / 2 + random_3 + random_4
                )
            
                fe.zPosition = -70//雲より手前、壁より奥
            
                //スプライトに物理演算を設定する
                fe.physicsBody = SKPhysicsBody(rectangleOf: featherTexture.size())
                
                //衝突の時に動かないように
                fe.physicsBody?.isDynamic = false
                
                //衝突カテゴリー設定
                fe.physicsBody?.categoryBitMask = self.itemCategory
                
                //衝突する相手を判定
                fe.physicsBody?.contactTestBitMask = self.birdCategory
                
            fe.run(moveFeather)
            
            self.featherNode.addChild(fe)
        })
        
        //時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 4)
        
        //アイテムを作成ｰ>時間待ちｰ>アイテムを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createFeather, waitAnimation]))
        
        //スプライトにアクションを設定する
        featherNode.run(repeatForeverAnimation)
        
        
    }
    
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーのときは何も表示しない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
           
            //ベストスコアか確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score + item > bestScore {
                bestScore = score + item
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore,forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            //アイテムと衝突
            print("itemGet")
            item += 1
            itemLabelNode.text = "Item Score:\(item)"
            self.featherNode.removeAllChildren()
            //item効果音。
            let itemSound = SKAction.playSoundFileNamed("13.mp3", waitForCompletion: false)
            self.featherNode.run(itemSound)
            
            //ベストスコアか確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score + item > bestScore {
                bestScore = score + item
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore,forKey: "BEST")
                userDefaults.synchronize()
            }
        }
        else {
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            //地面だけにして下に落ちるようにする
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll,completion:{
                self.bird.speed = 0
            })
        }
    }
    
    //再スタート
    func restrat() {
        item = 0
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemLabelNode.text = "Item Score:\(item)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        featherNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
}
