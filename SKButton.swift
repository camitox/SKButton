//
//  SKButton.swift
//  Geometric
//
//  Created by Camilo Vera Bezmalinovic on 11/23/14.
//  Copyright (c) 2014 Camilo Vera Bezmalinovic. All rights reserved.
//

import SpriteKit
import Foundation

enum SKButtonState : Int {
    case Normal
    case Highlighted
    case Disabled
    case Selected
}

enum SKButtonEvent : Int {
    case TouchDown
    case TouchUpInside
    case TouchUpOutside
    case TouchCancel
}

class SKButton: SKSpriteNode
{
    //defaults
    private let defaultFontName   = "Cartwheel"
    private let defaultTitleColor = SKColor.whiteColor()
    private let defaultFontSize   = CGFloat(20.0)
    
    //states
    private var backgrounds: Dictionary <SKButtonState,SKTexture> = [:]
    private var events     : Dictionary <SKButtonEvent,(target:NSValue,action:Selector)> = [:]
    private var titles     : Dictionary <SKButtonState,String> = [:]
    private var titleColors: Dictionary <SKButtonState,SKColor> = [:]
    
    private var currentState = SKButtonState.Normal

    var titleLabel : SKLabelNode?
    var titleEdgeInsets:UIEdgeInsets = UIEdgeInsetsZero {
        didSet
        {
            fixTitlePosition()
        }
    }
    
    
    //MARK: Inits
    override init(texture: SKTexture!, color: SKColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.userInteractionEnabled = true
    }
    
    convenience init(size:CGSize)
    {
        self.init(texture: nil, color: nil, size: size)
    }
    
    convenience init(frame:CGRect)
    {
        self.init(texture: nil, color: nil, size: frame.size)
        self.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: ButtonState
    //change the texture dependign these flags
    var enable:Bool{
        set {
            setState(SKButtonState.Disabled, active: !newValue)
        }
        get {
            return currentState != SKButtonState.Disabled
        }
    }
    var selected:Bool {
        set {
            setState(SKButtonState.Selected, active: newValue)
        }
        get {
            return currentState == SKButtonState.Selected
        }
    }
    var highlighted:Bool {
        set {
            setState(SKButtonState.Highlighted, active: newValue)
        }
        get {
            return currentState == SKButtonState.Highlighted
        }
    }
    
    private func setState(state: SKButtonState, active:Bool)
    {
        if active && currentState != state
        {
            currentState = state
            updateTexture()
            updateTitle()
        }
        else if !active && currentState == state
        {
            currentState = SKButtonState.Normal
            updateTexture()
            updateTitle()
        }
    }
    /*
        Will update the texture only if is needed or possible
    */
    private func updateTexture()
    {
        let newTexture = backgrounds[currentState]
        if newTexture != nil && newTexture != self.texture
        {
            self.texture = newTexture
        }
    }
    /*
        Probably this is not the best way to send events.... sorry future Camo
    */
    
    func setBackgroundTexture(texture:SKTexture?, forState state:SKButtonState)
    {
        if let _texture = texture
        {
            backgrounds[state] = _texture
            updateTexture()
        }
        else
        {
            assert(texture != nil, "SKButton: Texture should not be nil")
        }
    }

    //MARK: Actions
    
    func addTarget(target: AnyObject, action: Selector, forEvent event: SKButtonEvent)
    {
        events[event] = (NSValue(nonretainedObject: target), action)
    }
    
    private func sendEvent(buttonEvent:SKButtonEvent)
    {
        let event = events[buttonEvent]
        
        if event != nil && event!.target.nonretainedObjectValue != nil
        {
            var target:AnyObject = event!.target.nonretainedObjectValue!
            UIApplication.sharedApplication().sendAction(event!.action, to: target, from: self, forEvent: nil)
        }
        
    }
    
    //MARK: Label
    
    private func createTitleLabel()
    {
        let label = SKLabelNode(fontNamed: defaultFontName)
        label.position                = CGPointZero
        label.fontColor               = defaultTitleColor
        label.fontSize                = defaultFontSize
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        label.verticalAlignmentMode   = SKLabelVerticalAlignmentMode.Center
        label.zPosition               = self.zPosition+1
        self.addChild(label)
        self.titleLabel = label
    }
    
    private func updateTitle()
    {
        let title = titles[currentState]
        if title != nil
        {
            if titleLabel == nil
            {
                createTitleLabel()
            }
            
            if titleLabel?.text != title
            {
                titleLabel!.text = title!
                fixTitlePosition()
            }
            
            let color = titleColors[currentState]
            
            if color != nil && titleLabel?.fontColor != color
            {
                titleLabel!.fontColor = color!
            }
        }
    }
    //This is just for now... maybe I should create a SKLabel
    private func fixTitlePosition()
    {
        let fixedInsets   = UIEdgeInsetsMake(-titleEdgeInsets.top, titleEdgeInsets.left, -titleEdgeInsets.bottom, titleEdgeInsets.right)
        let originalFrame = titleLabel!.frame
        let maxFrame      = CGRectMake(-size.width/2, -size.height/2, size.width, size.height)
        let frame         = UIEdgeInsetsInsetRect(maxFrame, fixedInsets)
        
        titleLabel!.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        
    }
    
    
    func setTitle(title:String, forState state:SKButtonState)
    {
        titles[state] = title
        updateTitle()
    }
    
    func setTitleColor(color:SKColor, forState state:SKButtonState)
    {
        titleColors[state] = color
        updateTitle()
    }
    
    //MARK: Touches

    #if os(OSX)
    
    override func mouseDown(theEvent: NSEvent) {
        if self.enable
        {
            self.highlighted = true
            sendEvent(SKButtonEvent.TouchDown)
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        if self.enable
        {
            let location = theEvent.locationInNode(parent)
            self.highlighted = CGRectContainsPoint(self.frame, location)
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if self.enable
        {
            let location = theEvent.locationInNode(parent)
            
            if CGRectContainsPoint(self.frame, location)
            {
                sendEvent(SKButtonEvent.TouchUpInside)
            }
            else
            {
                sendEvent(SKButtonEvent.TouchUpOutside)
            }
            
            self.highlighted = false
        }
    }
    
    #else

    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)  {
        if self.enable
        {
            self.highlighted = true
            sendEvent(SKButtonEvent.TouchDown)
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent)  {
        if self.enable
        {
            let touch    = touches.first as! UITouch
            let location = touch.locationInNode(parent)
            self.highlighted = CGRectContainsPoint(self.frame, location)
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)  {
        if self.enable
        {
            let touch    = touches.first as! UITouch
            let location = touch.locationInNode(parent)
            
            if CGRectContainsPoint(self.frame, location)
            {
                sendEvent(SKButtonEvent.TouchUpInside)
            }
            else
            {
                sendEvent(SKButtonEvent.TouchUpOutside)
            }

            self.highlighted = false
        }
        
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
        sendEvent(SKButtonEvent.TouchCancel)
        self.highlighted = false
    }
    
    #endif

}
