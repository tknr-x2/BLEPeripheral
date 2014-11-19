//
//  ViewController.h
//  BLEPeripheral
//
//  Created by takanori uehara on 2014/11/13.
//  Copyright (c) 2014年 takanori uehara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController : UIViewController <CBPeripheralManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@property (nonatomic) CBPeripheralManager *peripheralManager;

@end

