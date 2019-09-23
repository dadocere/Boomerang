//
//  UICollectionView.swift
//  Boomerang
//
//  Created by Stefano Mondino on 20/01/2019.
//  Copyright © 2019 Synesthesia. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa


extension UICollectionView: ViewModelCompatibleType {
    public func set(viewModel: ViewModelType) {
        if let viewModel = viewModel as? ListViewModelType {
            self.boomerang.configure(with: viewModel)
        }
    }
}
extension Boomerang where Base: UICollectionView {
    
    public func configure(with viewModel: ListViewModelType, dataSource: CollectionViewDataSource? = nil, delegate: CollectionViewDelegate = CollectionViewDelegate()) {
        
        let dataSource = dataSource ?? CollectionViewDataSource(viewModel: viewModel)
        base.dataSource = dataSource
        base.delegate = delegate
        base.boomerang.internalDataSource = dataSource
        base.boomerang.internalDelegate = delegate
        viewModel.updates
            .asDriver(onErrorJustReturn: .none)
            .drive(base.rx.dataUpdates())
            .disposed(by: base.disposeBag)
    }
    
    public func dragAndDrop() -> Disposable {
        let gesture = UILongPressGestureRecognizer()
        base.addGestureRecognizer(gesture)
        return gesture.rx.event.bind {[weak base] gesture in
            guard let base = base else { return }
            switch gesture.state {
            case .began:
                guard let selectedIndexPath = base.indexPathForItem(at: gesture.location(in: base)) else {
                    break
                }
                base.beginInteractiveMovementForItem(at: selectedIndexPath)
            case .changed:
                base.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view ?? base))
            case .ended:
                base.endInteractiveMovement()
            default:
                base.cancelInteractiveMovement()
            }
        }
    }
}

extension Reactive where Base: UICollectionView {
    func dataUpdates() -> Binder<DataHolderUpdate> {
        return Binder(base) { base, updates in
            switch updates {
            case .reload(let updates) :
                _ = updates()
                base.reloadData()
                
            case .deleteItems(let updates):
                let indexPaths = updates()
                base.performBatchUpdates({[weak base] in
                    base?.deleteItems(at: indexPaths)
                    }, completion: { (completed) in
                        return
                })
            case .deleteSections(let updates):
                    let indexPaths = updates()
                    let indexSet = IndexSet(indexPaths.compactMap { $0.last })
                    base.performBatchUpdates({[weak base] in
                        base?.deleteSections(indexSet)
                        }, completion: { (completed) in
                            return
                    })
            case .insertItems(let updates):
                let indexPaths = updates()
                base.performBatchUpdates({[weak base] in
                    base?.insertItems(at: indexPaths)
                    }, completion: { (completed) in
                        return
                })
            
            case .insertSections(let updates):
                let indexPaths = updates()
                let indexSet = IndexSet(indexPaths.compactMap { $0.last })
                base.performBatchUpdates({[weak base] in
                    base?.insertSections(indexSet)
                    }, completion: { (completed) in
                        return
                })
            
            case .move(let updates):
                 _ = updates()
            
            default: break
            }
        }
    }
}
