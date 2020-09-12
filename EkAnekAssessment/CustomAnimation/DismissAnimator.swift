//
//  DismissAnimator.swift
//  EkAnekAssessment
//
//  Created by Ankit Batra on 12/09/20.
//  Copyright © 2020 EkAnek. All rights reserved.
//

import UIKit

class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.5
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        containerView.insertSubview(toView, belowSubview: fromView)
        UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: {
            fromView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: {_ in
            transitionContext.completeTransition(
                !transitionContext.transitionWasCancelled
            )
        })
    }
    
}
