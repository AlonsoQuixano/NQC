//
//  GameScene.swift
//  QuantChess
//
//  Created by  Mike Check on 09.04.2018.
//  Copyright © 2018 Alonso Quixano. All rights reserved.
//

import SpriteKit


class Rect: SKSpriteNode
{
    convenience init(color: UIColor, width: CGFloat, height: CGFloat)
    {
        self.init(color: color, size: CGSize(width: 0.1 * width, height: height * 0.9))
    }
    func DrawRect(parent: Figure, prob: Double)
    {
        self.size.height = (parent.parent as! Board).CellSize * CGFloat(0.9 * prob)
        self.zPosition = -1
        parent.addChild(self)
        self.anchorPoint = CGPoint(x: parent.g_col == 1 ? -4 : 5, y: 0.5)
        let x =  0 //If not 0 rects run away from screen. DO NOT TOUCH
        let y = 0
        self.position = CGPoint(x: x, y: y)
    }
}

class Stamp:SKSpriteNode
{
    convenience init(col: Int, parent: Board)
    {
        if col == 1
        {self.init(imageNamed: "w_win")}
        else
        {self.init(imageNamed: "b_win")}
        parent.addChild(self)
        self.position = CGPoint(x: 0, y: 0)
        self.size = CGSize(width: 0.3, height: 0.3)
        self.zPosition = 5
    }
}


class Figure: SKSpriteNode
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "testfig")}
        else
        {self.init(imageNamed: "testfig")}
        g_col = col
        ID = set_ID
    }
    
    var g_col: Int = 0 //color. Don't remember what "g_" means
    
    func CorrMoves(start_x: Int, start_y: Int, board: quant_board) -> [[Int]]
    {
        var goodMoves:[[Int]] = []
        for i in -8...8 {
            for j in -8...8 {
                if (start_x + i >= 0 && start_x + i < 8) &&
                    (start_y + j >= 0 && start_y + j < 8) &&
                    (board.board[start_x + i][start_y + j] != g_col) &&
                    CorrMoveConditions(start_x: start_x, start_y: start_y,
                                         dx: i, dy: j, board: board)
                {
                    goodMoves.append([i, j])
                }
            }
        }
        return goodMoves
    } //function to check if you move figure correctly
    func CorrMoveConditions(start_x: Int, start_y: Int,
                              dx: Int, dy: Int, board: quant_board) -> Bool {return true}
    var touched = 0 //let understand if we heck or unchek figure
    let image_inc: CGFloat = 1.4
    var x: Int = 0 //position
    var y: Int = 0 //position
    var ID: Int = 0 //need for understanding when conflict appears
    
    func isQuantumMove() -> Bool
    {
        return self.colorBlendFactor == 0.5
    }
    
    func onTap(parent: Board)
    {
        if touched == 0
        {
            self.size = CGSize(width: self.size.width * image_inc, height: self.size.height * image_inc)
            touched = 1
        }
        else if touched == 1
        {
            self.size = CGSize(width: parent.CellSize, height: parent.CellSize)
            touched = 0
        }
        else if touched == 2
        {
            self.colorBlendFactor = 0
            self.size = CGSize(width: parent.CellSize, height: parent.CellSize)
            touched = 0
        }
    }
    
    func onDoubleTap()
    {
        if touched == 1
        {
            self.color = .red
            self.colorBlendFactor = 0.5
            touched = 2
        }
        
    }

    func moveby(dx: CGFloat, dy: CGFloat, parent: Board) -> Bool
    {
        let old_x = x
        let old_y = y
        let move_x = dx * parent.CellSize
        let move_y = dy * parent.CellSize
        var did_moved: Bool = false //Show if at least on one of boards the figure was moved
        var did_blocked: Bool = false //Show if at least on one of boards the figure was blocked
        var passed: [quant_board] = []
        var conflict: [quant_board] = []
        var has_castle_conflict: Bool = false
        var has_conflict = false
        var king_eaten = false
        
        
        
        if !((x + Int(dx) >= 0) && (y + Int(dy) >= 0) && (x + Int(dx) < 8) && (y + Int(dy) < 8))
        {
            return false
        }
        if parent.showboard.figs[x + Int(dx)][y + Int(dy)] != nil && (parent.showboard.figs[x + Int(dx)][y + Int(dy)] as! Figure).ID != self.ID
        {
            has_conflict = true
            if(parent.showboard.figs[x + Int(dx)][y + Int(dy)] as! Figure).ID == -16 * g_col
            {
                king_eaten = true
            }
        }
        
        if abs(self.ID) == 16 && abs(dx) == 2 && dy == 0 //if we move king far maybe it's a castle
        {
            has_castle_conflict = true
        }
        
        for board in parent.boards //on all board make move if possible
        {
            if board.board[x + Int(dx)][y + Int(dy)] != 0 && has_conflict
            {
                conflict.append(board)
            }
            if board.board[x][y] != 0
            {
                if CorrMoves(start_x: x, start_y: y, board: board).contains(where: {$0 == [Int(dx), Int(dy)]}) && (!has_castle_conflict || (parent.showboard.figs[dx > 0 ? 7: 0][y] as! Figure).ID == g_col * (dx > 0 ?  10 : 9))
                //I ❤️ crocodiles
                {
                    if abs(self.ID) <= 8 && dy == 2
                    {
                        (self as! Pawn).start_jump = true
                    }
                    if let del_ind = conflict.index(where: {$0 === board})
                    {
                        conflict.remove(at: del_ind) //Hope it is working!
                    }
                    did_moved = true
                    passed.append(board)
                    board.set(i: x,j: y,val: 0)
                    x += Int(dx)
                    y += Int(dy)
                    if self.ID == g_col * 9
                    {
                        board.l_rook_move[g_col == 1 ? 1:0] = true
                    }
                    if self.ID == g_col * 10
                    {
                        board.r_rook_move[g_col == 1 ? 1:0] = true
                    }
                    if self.ID == g_col * 16
                    {
                        board.king_move[g_col == 1 ? 1 : 0] = true
                    }
                    if king_eaten && board.board[x][y] == -g_col && board.win == 0
                    {
                        board.win = g_col
                    }
                    board.set(i: x, j: y, val: self.g_col)
                    if has_castle_conflict
                    {
                        if dx > 0
                        {
                            board.set(i: x-1, j: y, val: self.g_col)
                        }
                        else
                        {
                            board.set(i: x+1, j: y, val: self.g_col)
                        }
                    }
                }
                else
                {
                    if has_castle_conflict && conflict.index(where: {$0 === board}) == nil
                    {
                        conflict.append(board)
                    }
                    did_blocked = true
                }
            }
        }
        
        if did_moved && did_blocked //correct move but only on some boards it's possiblle -- need to duplicate
        {
            let Type = type(of: self)
            let new_fig = Type.init(col: g_col, set_ID: ID) //create a figure of the same type and color
            new_fig.put(ParentNode: parent, position: [Int32(old_x), Int32(old_y)], boards: []) //[] -- because we do not need to change any board yet
        }
        if did_moved
        {
            onTap(parent: parent)
            if conflict.count != 0
            {
                let conflict_solution = (Int(arc4random_uniform(UInt32(passed.count + conflict.count) + 1)) > passed.count) //True -- you loose (opponents figure saved)
                if conflict_solution
                {
                    for board in passed
                    {
                        parent.boards = parent.boards.filter {$0 !== board}
                    }
                }
                else //You are lucky
                {
                    for board in conflict
                    {
                        parent.boards = parent.boards.filter {$0 !== board}
                    }
                    AcceptMove(move_x: move_x, move_y: move_y, has_castle_conflict: has_castle_conflict, parent: parent)
                }
            }
            else
            {
                AcceptMove(move_x: move_x, move_y: move_y, has_castle_conflict: has_castle_conflict, parent: parent)
            }
            if !did_blocked
            {
                parent.showboard.set(i: old_x, j: old_y, val: nil)
                if has_castle_conflict
                {
                    if dx == 2
                    {
                        parent.showboard.set(i: 7, j: y, val: nil)
                    }
                    else
                    {
                        parent.showboard.set(i: 0, j: y, val: nil)
                    }
                }
            }
            parent.showboard.update(boards: parent.boards)
            parent.showboard.draw(parent: parent)
        }
        return did_moved
    }
    
    func AcceptMove(move_x: CGFloat, move_y: CGFloat, has_castle_conflict: Bool, parent: Board)
    {
        self.run(SKAction.move(by: CGVector(dx: move_x,dy: move_y), duration: 0.1))
        if has_castle_conflict //if the move is castle
        {
            if move_x > 0
            {
                (parent.showboard.figs[7][y] as! Figure).run(SKAction.move(by: CGVector(dx: -2 * parent.CellSize,dy: 0), duration: 0.1))
                (parent.showboard.figs[7][y] as! Figure).x -= 2
                parent.showboard.set(i: x, j: y, val: parent.showboard.figs[7][y])
            }
            else
            {
                (parent.showboard.figs[0][y] as! Figure).run(SKAction.move(by: CGVector(dx: 3 * parent.CellSize,dy: 0), duration: 0.1))
                (parent.showboard.figs[0][y] as! Figure).x += 3
                parent.showboard.set(i: x, j: y, val: parent.showboard.figs[0][y])
            }
        }
        parent.showboard.set(i: x, j: y, val: self)
        if abs(self.ID) < 9 && (self.y == 7 || self.y == 0)   //if pawn reach the end of the desk
        {
            parent.choice(pawn: self as! Pawn)
        }
    }
    
    
    func put(ParentNode: Board, position: int2, boards: [quant_board]){
        ParentNode.addChild(self)
        x = Int(position[0])
        y = Int(position[1])
        var put_x = -ParentNode.size.width / 2 + ParentNode.boundSize + 0.5 * ParentNode.CellSize
        put_x += CGFloat(position[0]) * ParentNode.CellSize //Beautiful example why this language is a piece of.....is not very good
        var put_y = -ParentNode.size.width / 2 + ParentNode.boundSize + 0.5 * ParentNode.CellSize
        put_y += CGFloat(position[1]) * ParentNode.CellSize
        self.position = CGPoint(x: put_x, y: put_y)
        self.size = CGSize(width: ParentNode.CellSize, height: ParentNode.CellSize)
        self.zPosition = 2
        for board in boards
        {
            board.set(i: Int(position[0]), j: Int(position[1]), val: g_col) //Ставим фигуру на досках указнных в массивах
        }
        if self.ID != 0
        {
            ParentNode.showboard.set(i: Int(position[0]), j: Int(position[1]), val: self)
        }
    }
}


class Horse: Figure
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_horse")}
        else
        {self.init(imageNamed: "b_horse")}
        g_col = col
        ID = set_ID
    }
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        return (abs(dx) + abs(dy) == 3) && (abs(dx * dy) == 2)
    }
}


class King: Figure
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_king")}
        else
        {self.init(imageNamed: "b_king")}
        g_col = col
        ID = set_ID
    }
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        if (abs(dx) == 2)&&(dy == 0)&&(!board.king_move[g_col == 1 ? 1 : 0])&&(dx > 0 && !board.r_rook_move[g_col == 1 ? 1 : 0] || dx<0 && !board.l_rook_move[g_col == 1 ? 1 : 0]) //castle
        {
            let sign =  dx > 0 ? 1 : -1
            var ch_x = x + sign
            while ch_x != 0 &&  ch_x != 7
            {
                if board.board[ch_x][y] != 0
                {return false}
                ch_x += sign
            }
            return true
        }
        return (abs(dx) <= 1) && (abs(dy) <= 1) && (abs(dx) + abs(dy) != 0)
    }
}


class Queen: Figure
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_queen")}
        else
        {self.init(imageNamed: "b_queen")}
        g_col = col
        ID = set_ID
    }
    
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        let kx = (dx == 0) ? 0 : Int(dx / abs(dx))
        let ky = (dy == 0) ? 0 : Int(dy / abs(dy))
        let d: Int = max(_: abs(dx), _: abs(dy))
        if abs(dx) != abs(dy) && dx*dy != 0 || abs(dx) + abs(dy) == 0
        {return false}
        if d > 1 //this language makes me suffer
        {
            for i in 1 ..< d
            {
                if board.board[x + i*kx][y + i*ky] != 0
                {return false}
            }
        }
        return true
    }
}


class Rook: Figure
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_rook")}
        else
        {self.init(imageNamed: "b_rook")}
        g_col = col
        ID = set_ID
    }
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        let kx = (dx == 0) ? 0 : Int(dx / abs(dx))
        let ky = (dy == 0) ? 0 : Int(dy / abs(dy))
        let d: Int = max(_: abs(dx), _ : abs(dy))
        if kx*ky != 0 || abs(dx) + abs(dy) == 0
        {return false}
        if d > 1 //this language makes me suffer
        {
            for i in 1 ..< d
            {
                if board.board[x + i*kx][y + i*ky] != 0
                {return false}
            }
        }
        return true
    }
}

class Bishop: Figure
{
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_bishop")}
        else
        {self.init(imageNamed: "b_bishop")}
        g_col = col
        ID = set_ID
    }
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        let kx = (dx == 0) ? 0 : Int(dx / abs(dx))
        let ky = (dy == 0) ? 0 : Int(dy / abs(dy))
        let d: Int = max(_: abs(dx), _ : abs(dy))
        if abs(dx) != abs(dy) || abs(dx) + abs(dy) == 0
        {return false}
        if d > 1 //this language makes me suffer
        {
            for i in 1 ..< d
            {
                if board.board[x + i*kx][y + i*ky] != 0
                {return false}
            }
        }
        return true
    }
}


class Pawn: Figure
{
    var start_jump = false
    required convenience init(col: Int, set_ID: Int)
    {
        if col == 1
        {self.init(imageNamed: "w_pawn")}
        else
        {self.init(imageNamed: "b_pawn")}
        g_col = col
        ID = set_ID
    }
    
    override func CorrMoveConditions(start_x: Int, start_y: Int, dx: Int, dy: Int, board: quant_board) -> Bool {
        //more crocodiles to the God of crocodiles!
        return dy == g_col && dx == 0 && board.board[x][y + g_col] == 0 || 1 == abs(dx) && dy == g_col && board.board[x + dx][y + dy] == -g_col || dy == 2*g_col && dx == 0 && y == ((g_col == 1) ? 1 : 6)
    }
    override func onDoubleTap() {}
}

