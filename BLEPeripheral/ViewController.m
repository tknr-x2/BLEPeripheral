//
//  ViewController.m
//  BLEPeripheral
//
//  Created by takanori uehara on 2014/11/13.
//  Copyright (c) 2014年 takanori uehara. All rights reserved.
//

#import "ViewController.h"

#define LOCAL_NAME @"BLE Peripheral DEMO"
#define SERVICE_UUID @"00000000-0000-0000-0000-000000000000"
#define CHARACTERISTIC_UUID @"00000000-0000-0000-0000-000000000000"

@interface ViewController () {
    CGFloat displayWidth;
    CGFloat displayHeight;
    
    CBUUID *serviceUUID;
    
    UIScrollView *contentsView;
    CGFloat tempScrollTop;
    
    UILabel *statusLabel;
    UILabel *peripheralInfoLabel;
    UIButton *startButton;
    
    NSArray *presetUUIDs;
    UIPickerView *presetUUIDsPicker;
    
    NSString *localName;
    UITextField *localNameTextField;
}

@end

@implementation ViewController

-(void)display {
    contentsView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, displayWidth, displayHeight)];
    [self.view addSubview:contentsView];
    
    UIView *view;
    UILabel *label;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, displayWidth, 30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"BLE Peripheral DEMO";
    label.font = [UIFont systemFontOfSize:32];
    label.textColor = [UIColor blackColor];
    [contentsView addSubview:label];
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, label.frame.origin.y+label.frame.size.height+20, displayWidth, 30)];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.text = @"Wait ...";
    statusLabel.font = [UIFont systemFontOfSize:24];
    statusLabel.textColor = [UIColor blackColor];
    [contentsView addSubview:statusLabel];
    
    peripheralInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, statusLabel.frame.origin.y+statusLabel.frame.size.height+20, displayWidth, 80)];
    peripheralInfoLabel.textAlignment = NSTextAlignmentCenter;
    peripheralInfoLabel.numberOfLines = 0;
    peripheralInfoLabel.text = @"";
    peripheralInfoLabel.font = [UIFont systemFontOfSize:12];
    peripheralInfoLabel.textColor = [UIColor blackColor];
    [contentsView addSubview:peripheralInfoLabel];
    
    startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startButton.frame = CGRectMake(displayWidth*0.1, peripheralInfoLabel.frame.origin.y+peripheralInfoLabel.frame.size.height+20, displayWidth*0.8, 40);
    [startButton setTitle:@"Start Advertising" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    startButton.layer.borderWidth = 1;
    startButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    startButton.layer.cornerRadius = 4.0;
    [startButton addTarget:self action:@selector(toggleAdvertising:) forControlEvents:UIControlEventTouchUpInside];
    [contentsView addSubview:startButton];
    
    presetUUIDs = @[
                    @"Free input",
                    SERVICE_UUID,
                    @"913C64F0-9886-4FC3-B11C-78581F21CDB4",
                    ];
    serviceUUID = [CBUUID UUIDWithString:presetUUIDs[1]]; // serviceUUID 初期値
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, startButton.frame.origin.y+startButton.frame.size.height+20, displayWidth, 30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Service UUID";
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor blackColor];
    [contentsView addSubview:label];
    view = [[UIView alloc] initWithFrame:CGRectMake(0, label.frame.origin.y+label.frame.size.height, displayWidth, 100)];
    view.clipsToBounds = YES;
    [contentsView addSubview:view];
    presetUUIDsPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, view.frame.size.height/2-81, displayWidth, 162)];
    presetUUIDsPicker.delegate = self;
    presetUUIDsPicker.dataSource = self;
    presetUUIDsPicker.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1];
    [presetUUIDsPicker selectRow:1 inComponent:0 animated:NO]; // 初期選択
    presetUUIDsPicker.userInteractionEnabled = NO;
    presetUUIDsPicker.alpha = 0.5;
    [view addSubview:presetUUIDsPicker];
    
    localName = LOCAL_NAME;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, view.frame.origin.y+view.frame.size.height+20, displayWidth, 30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Local Name";
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor blackColor];
    [contentsView addSubview:label];
    view = [[UIView alloc] initWithFrame:CGRectMake(displayWidth*0.05, label.frame.origin.y+label.frame.size.height, displayWidth*0.9, 30)];
    view.clipsToBounds = YES;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    view.layer.cornerRadius = 4.0;
    [contentsView addSubview:view];
    localNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, view.frame.size.width-20, view.frame.size.height)];
    localNameTextField.delegate = self;
    localNameTextField.returnKeyType = UIReturnKeyDone;
    localNameTextField.text = localName;
    localNameTextField.userInteractionEnabled = NO;
    localNameTextField.alpha = 0.5;
    [view addSubview:localNameTextField];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    displayWidth = self.view.frame.size.width;
    displayHeight = self.view.frame.size.height;
    
    // キーボード表示/非表示通知登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self display];
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

// アドバタイズ切り替え
- (void)toggleAdvertising {
    [self toggleAdvertising:nil];
}
- (void)toggleAdvertising:(id)sender {
    if ([self.peripheralManager isAdvertising]) {
        [self stopAdvertising];
    } else {
        [self startAdvertising];
    }
}

// アドバタイズ停止処理
- (void)stopAdvertising {
    NSLog(@"stopAdvertising");
    
    statusLabel.text = @"Stop";
    [startButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [startButton setTitle:@"Start Advertising" forState:UIControlStateNormal];
    
    presetUUIDsPicker.userInteractionEnabled = YES;
    presetUUIDsPicker.alpha = 1;
    localNameTextField.userInteractionEnabled = YES;
    localNameTextField.alpha = 1;
    
    if ([self.peripheralManager isAdvertising]) [self.peripheralManager stopAdvertising];
}

// アドバタイズ開始処理
- (void)startAdvertising {
    NSLog(@"startAdvertising");
    
    statusLabel.text = @"Services registration ...";
    [startButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [startButton setTitle:@"Stop Advertising" forState:UIControlStateNormal];
    
    presetUUIDsPicker.userInteractionEnabled = NO;
    presetUUIDsPicker.alpha = 0.5;
    localNameTextField.userInteractionEnabled = NO;
    localNameTextField.alpha = 0.5;
    
    // サービス全削除
    [self.peripheralManager removeAllServices];
    
    // サービス設定
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    
    
    // キャラクタリスティック設定
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]
                                                             properties:CBCharacteristicPropertyRead
                                                                  value:nil
                                                            permissions:CBAttributePermissionsReadable];
    service.characteristics = @[characteristic];
    
    // サービス登録
    [self.peripheralManager addService:service];
}

// サービス登録完了時
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"peripheralManager:didAddService:error:");
    
    if (error) {
        statusLabel.text = @"Service registration failure";
        [self startAdvertising];
        
        NSLog(@"error = %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    statusLabel.text = @"Start advertising ...";
    
    // アドバタイズ開始
    [self.peripheralManager startAdvertising:@{
                                               CBAdvertisementDataLocalNameKey: localName, // セントラル側で表示される機器名
                                               CBAdvertisementDataServiceUUIDsKey: @[
                                                       serviceUUID,
                                                       ],
                                               }];
}

// アドバタイズ開始時
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"peripheralManagerDidStartAdvertising:error:");
    
    if (error) {
        statusLabel.text = @"Advertising failed to start";
        [self startAdvertising];
        
        NSLog(@"error = %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    
    statusLabel.text = @"Advertising ...";
    
    peripheralInfoLabel.text = [NSString stringWithFormat:@"Local Name: %@\nService UUID: %@",
                                localName,
                                serviceUUID
                                ];
}

// ステータス変更時
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    NSLog(@"peripheralManagerDidUpdateState:: peripheral.state = %ld", (long)peripheral.state);
    
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown:
            // 不明な状態 (初期値)
            NSLog(@"unknown state (default)");
            break;
        case CBPeripheralManagerStateResetting:
            // 一時的に切断され、再設定された
            NSLog(@"resetting");
            break;
        case CBPeripheralManagerStateUnsupported:
            // BLE がサポートされていない
            NSLog(@"BLE is unsupported");
            break;
        case CBPeripheralManagerStateUnauthorized:
            // BLE が許可されていない
            NSLog(@"BLE is unauthorized");
            break;
        case CBPeripheralManagerStatePoweredOff:
            // Bluetooth がオフ
            NSLog(@"bluetooth power off");
            break;
        case CBPeripheralManagerStatePoweredOn:
            // Bluetooth がオン
            NSLog(@"bluetooth power on");
            
            [self toggleAdvertising];
            
            break;
        default:
            break;
    }
}

// UIPickerView デリゲートメソッド
// 列数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1;
}
// 行数
- (NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [presetUUIDs count];
}
// 表示内容を返す
- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return presetUUIDs[row];
}
// ビューを返す
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *label = (id)view;
    if (!label) {
        label= [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [pickerView rowSizeForComponent:component].width, [pickerView rowSizeForComponent:component].height)];
    }
    label.textAlignment = NSTextAlignmentCenter;
    label.text = presetUUIDs[row];
    
    // フォントサイズ設定
    if (row == 0) {
        label.font = [UIFont systemFontOfSize:20];
    } else {
        label.font = [UIFont systemFontOfSize:14];
    }
    
    return label;
}
// 選択ビュー取得
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        // フリー入力
        // 後々実装 ...
        
        serviceUUID = [CBUUID UUIDWithString:presetUUIDs[1]];
    } else {
        serviceUUID = [CBUUID UUIDWithString:presetUUIDs[row]];
    }
}

// メッセージ入力終了処理
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    localName = textField.text;
    [textField resignFirstResponder];
    return YES;
}

// キーボード表示時
- (void)keyboardWillShow:(NSNotification*)notification {
    NSLog(@"keyboardWillShow");
    // スクロール位置一時保存
    tempScrollTop = contentsView.scrollsToTop;
    
    // キーボードサイズ取得
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 最適位置までスクロール
    CGPoint scrollPoint = CGPointMake(0, ([localNameTextField superview].frame.origin.y+[localNameTextField superview].frame.size.height+5)-(displayHeight-keyboardRect.size.height));
    [contentsView setContentOffset:scrollPoint animated:YES];
}
// キーボード非表示時
- (void)keyboardWillHide:(NSNotification*)notification {
    NSLog(@"keyboardWillHide");
    
    // スクロール位置を戻す
    [contentsView setContentOffset:CGPointMake(0.0, tempScrollTop) animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
