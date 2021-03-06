//
//  File.swift
//  Quantum Chess
//
//  Created by  Mike Check on 11.05.2018.
//  Copyright © 2018 Alonso Quixano. All rights reserved.


import SpriteKit


class quant_board
{
    var board: [[Int]] = []
    var win: Int = 0
    var r_rook_move: [Bool] = [false, false]
    var l_rook_move: [Bool] = [false, false]
    var king_move: [Bool] = [false, false]
    init()
    {
        for _ in 0..<8
        {
            self.board.append([0, 0, 0, 0, 0, 0, 0, 0])
        }
    }
    
    func set(i: Int,  j: Int, val: Int)
    {
        board[i][j] = val
    }
    
    func copy() -> quant_board{
        let bord = quant_board()
        for i in 0..<8 {
            for j in 0..<8 {
                bord.board[i][j] = self.board[i][j]
            }
        }
        bord.win = win
        for i in 0..<2 {
            bord.r_rook_move[i] = r_rook_move[i]
            bord.l_rook_move[i] = l_rook_move[i]
            bord.king_move[i] = king_move[i]
        }
        return bord
    }
}


class show_board
{
    var figs: [[AnyObject?]] = []
    var probability: [[Double]] = []
    init()
    {
        for _ in 0..<8
        {
            self.figs.append([nil, nil, nil, nil, nil, nil, nil, nil])
            self.probability.append([0, 0, 0, 0, 0, 0, 0, 0])
        }
    }
    func set(i: Int,  j: Int, val: AnyObject?)
    {
        figs[i][j] = val
    }
    func update(boards: [quant_board])
    {
        if boards.count == 0
        {
            return
        }
        for i in 0...7
        {
            for j in 0...7
            {
                probability[i][j] = 0
            }
        }
        for board in boards
        {
            for i in 0...7
            {
                for j in 0...7
                {
                    probability[i][j] += abs(Double(board.board[i][j]))
                }
            }
        }
        for i in 0...7
        {
            for j in 0...7
            {
                probability[i][j] /=  Double(boards.count)
            }
        }
    }
    
    func draw(parent: Board)
    {
        for kid in parent.children
        {
            if let child = kid as? Figure
            {
                if child.ID == 0
                {
                    continue
                }
                for rec in child.children //I don't know how to remove it correctly
                {
                    rec.removeFromParent()
                }
                if (parent.showboard.figs[child.x][child.y] as! Figure) !== child || (abs(parent.showboard.probability[child.x][child.y]) < 1e-8)  //if figure was removed by otherr, or all desks with it were destroyed
                {
                    child.removeFromParent()
                }
                else
                {
                    let col = child.g_col == 1 ? UIColor.blue : UIColor.red
                    let new_rect = Rect(color: col, width: parent.CellSize, height: parent.CellSize) //You think it means that the rect has the same size as the cell. No.
                    new_rect.DrawRect(parent: child, prob: parent.showboard.probability[child.x][child.y])
                }
            }
        }
    }
    
    func check(boards: [quant_board]) -> Bool
    {
        for board in boards
        {
            if board.win == 0
            {
                return false
            }
        }
        return true
    }
}


class Board: SKSpriteNode
{
    var CellSize: CGFloat = 0
    var boundSize: CGFloat = 0
    var showboard: show_board = show_board()
    var boards: [quant_board] = [quant_board()]
    var choice_time: Bool = false
    var transformingPawn: Pawn? = nil
    var buttons: [Button] = []
    
    func create(ParentNode: SKNode)
    {
        ParentNode.addChild(self)
        self.size = CGSize(width: 0.5, height: 0.5)
        self.position = CGPoint(x: 0.5, y: 0.5)
        self.CellSize =  1 / 9 * size.width
        self.boundSize = 1 / 18 * size.width
        self.zPosition = -1 //Will it prevent figures from hiding?
        
        buttons.append(Button(parent: self, col: 1))
        buttons.append(Button(parent: self, col: -1))
        
        // THINK ABOUT "Friend conflict" WHEN YOU PUT THE FIGURE ON THE FIGURE OF YOUR COLOR
        // SHOULD YOU CONTROL THIS CONFLICT
        // SHOULD YOU IGNORE MERGERING FIGURES OF THE SAME TYPE IF THEY WERE NOT EQUIALENT EQUIVALENT AT THE BEGINING???
        
        //pawns
        var w_pawn: [Pawn] = []
        var b_pawn: [Pawn] = []
        for i in 0...7
        {
            w_pawn.append(Pawn(col: 1, set_ID: i+1))
            w_pawn[i].put(ParentNode: self, position: [Int32(i), 1], boards: self.boards)
            b_pawn.append(Pawn(col: -1, set_ID: -(i+1)))
            b_pawn[i].put(ParentNode: self, position: [Int32(i), 6], boards: self.boards)
        }
        //rooks
        let w_rook_1 = Rook(col: 1, set_ID: 9)
        w_rook_1.put(ParentNode: self, position: [0, 0], boards: self.boards)
        let w_rook_2 = Rook(col: 1, set_ID: 10)
        w_rook_2.put(ParentNode: self, position: [7, 0], boards: self.boards)
        let b_rook_1 = Rook(col: -1, set_ID: -9)
        b_rook_1.put(ParentNode: self, position: [0, 7], boards: self.boards)
        let b_rook_2 = Rook(col: -1, set_ID: -10)
        b_rook_2.put(ParentNode: self, position: [7, 7], boards: self.boards)
        //horses
        let w_horse_1 = Horse(col: 1, set_ID: 11)
        w_horse_1.put(ParentNode: self, position: [1, 0], boards: self.boards)
        let w_horse_2 = Horse(col: 1, set_ID: 12)
        w_horse_2.put(ParentNode: self, position: [6, 0], boards: self.boards)
        let b_horse_1 = Horse(col: -1, set_ID: -11)
        b_horse_1.put(ParentNode: self, position: [1, 7], boards: self.boards)
        let b_horse_2 = Horse(col: -1, set_ID: -12)
        b_horse_2.put(ParentNode: self, position: [6, 7], boards: self.boards)
        //bishops
        let w_bishop_1 = Bishop(col: 1, set_ID: 13)
        w_bishop_1.put(ParentNode: self, position: [2, 0], boards: self.boards)
        let w_bishop_2 = Bishop(col: 1, set_ID: 14)
        w_bishop_2.put(ParentNode: self, position: [5, 0], boards: self.boards)
        let b_bishop_1 = Bishop(col: -1, set_ID: -13)
        b_bishop_1.put(ParentNode: self, position: [2, 7], boards: self.boards)
        let b_bishop_2 = Bishop(col: -1, set_ID: -14)
        b_bishop_2.put(ParentNode: self, position: [5, 7], boards: self.boards)
        //queens
        let w_queen = Queen(col: 1, set_ID: 15)
        w_queen.put(ParentNode: self, position: [3, 0], boards: self.boards)
        let b_queen = Queen(col: -1, set_ID: -15)
        b_queen.put(ParentNode: self, position: [3, 7], boards: self.boards)
        //king
        let w_king = King(col: 1, set_ID: 16)
        w_king.put(ParentNode: self, position: [4, 0], boards: self.boards)
        let b_king = King(col: -1, set_ID: -16)
        b_king.put(ParentNode: self, position: [4, 7], boards: self.boards)
    }
    
    func choice(pawn: Pawn)
    {
        let f1 = Rook(col: pawn.g_col, set_ID: 0)
        f1.put(ParentNode: self, position: [2, pawn.g_col == 1 ? 9 : -2], boards: [])
        let f2 =  Horse(col: pawn.g_col, set_ID: 0)
        f2.put(ParentNode: self, position: [3, pawn.g_col == 1 ? 9 : -2], boards: [])
        let f3 =  Bishop(col: pawn.g_col, set_ID: 0)
        f3.put(ParentNode: self, position: [4, pawn.g_col == 1 ? 9 : -2], boards: [])
        let f4 =  Queen(col: pawn.g_col, set_ID: 0)
        f4.put(ParentNode: self, position: [5, pawn.g_col == 1 ? 9 : -2], boards: [])
        choice_time = true
        transformingPawn = pawn
    }
    
    func makeChoice()
    {
        transformingPawn?.removeFromParent()
        choice_time = false
    }
}

class Button: SKSpriteNode
{
    var bCol: Int = 1
    convenience init(parent: Board, col: Int)
    {
        self.init(imageNamed: col == 1 ? "capitulate_active" : "capitulate_inactive")
        parent.addChild(self)
        self.size = CGSize(width: 0.32 * Double(col), height: 0.08 * Double(col))
        bCol = col
        self.position = CGPoint(x: 0, y: -0.4 * Double(col))
    }
    func switcher(turn: Int)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){ //make code a bit later
            if turn == self.bCol
            {
                self.texture = SKTexture(imageNamed: "capitulate_active")
            }
            else
            {
                self.texture = SKTexture(imageNamed: "capitulate_inactive")
            }
        }
    }
    func onTap(parent: Board, turn: Int) -> Bool
    {
        if bCol == turn
        {
            for board in parent.boards
            {
                if board.win == 0
                {
                    board.win = -turn
                }
            }
            return true
        }
        return false
    }
}
