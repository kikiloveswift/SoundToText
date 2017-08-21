//
//  ViewController.m
//  SoundToText
//
//  Created by kong on 2017/8/21.
//  Copyright © 2017年 konglee. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>

@interface ViewController ()<UIGestureRecognizerDelegate>
{
    dispatch_source_t time;
}

@property (weak, nonatomic) IBOutlet UITextView *sTextView;

@property (weak, nonatomic) IBOutlet UIButton *sbtn;

@property (nonatomic, assign) NSInteger seconds;

@property (nonatomic, assign) SFSpeechRecognizerAuthorizationStatus stas;

@property (nonatomic, strong) AVAudioEngine *audioEngine;                           // 声音处理器

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;                 // 语音识别器

@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *speechRequest; // 语音请求对象

@property (nonatomic, strong) SFSpeechRecognitionTask *currentSpeechTask;           // 当前语音识别进程


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self configSetting];
}

- (void)initUI
{
    [_sbtn setBackgroundColor:[UIColor lightGrayColor]];
    _seconds = 0;
    UILongPressGestureRecognizer *lgesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(gesAction:)];
    lgesture.minimumPressDuration = 0.0;
    [_sbtn addGestureRecognizer:lgesture];
    
    
}

- (void)configSetting
{
    // 初始化
    self.audioEngine = [AVAudioEngine new];
    // 这里需要先设置一个AVAudioEngine和一个语音识别的请求对象SFSpeechAudioBufferRecognitionRequest
    self.speechRecognizer = [[SFSpeechRecognizer alloc]initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status)
     {
         if (status != SFSpeechRecognizerAuthorizationStatusAuthorized)
         {
             // 如果状态不是已授权则return
             return;
         }
         
         // 初始化语音处理器的输入模式
         [self.audioEngine.inputNode installTapOnBus:0 bufferSize:1024 format:[self.audioEngine.inputNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer,AVAudioTime * _Nonnull when)
          {
              // 为语音识别请求对象添加一个AudioPCMBuffer，来获取声音数据
              [self.speechRequest appendAudioPCMBuffer:buffer];
          }];
         // 语音处理器准备就绪（会为一些audioEngine启动时所必须的资源开辟内存）
         [self.audioEngine prepare];
         
     }];
    
}


- (void)gesAction:(UILongPressGestureRecognizer *)ges
{
    switch (ges.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"开始");
            [self startCounting];
            if (self.currentSpeechTask.state == SFSpeechRecognitionTaskStateRunning)
            {   // 如果当前进程状态是进行中
                NSLog(@"当前进程正在进行");
                // 停止语音识别
                [self stopDictating];
            }
            else
            {   // 进程状态不在进行中
                // 开启语音识别
                NSLog(@"当前进程空闲");

                [self startDictating];
            }

        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"结束");
            [self cancelCounting];
            [self stopDictating];
        }
            break;
        default:
            break;
    }
}

- (void)startCounting
{
    if (time)
    {
        dispatch_source_cancel(time);
    }
    __weak typeof(self) weakself = self;
    time = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_timer(time, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(time, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"倒计时开始");
            [weakself.sbtn setBackgroundColor:[UIColor grayColor]];
            [weakself.sbtn setTitle:[NSString stringWithFormat:@"按住(%ld)秒",++weakself.seconds] forState:UIControlStateNormal];
        });
    });
    dispatch_resume(time);
}

- (void)cancelCounting
{
    NSLog(@"结束说话");
    if (time)
    {
        dispatch_source_cancel(time);
    }
    [_sbtn setBackgroundColor:[UIColor lightGrayColor]];
    _seconds = 0;
    [_sbtn setTitle:@"按住说话" forState:UIControlStateNormal];
}

- (void)startDictating
{
    NSError *error;
    // 启动声音处理器
    [self.audioEngine startAndReturnError: &error];
    // 初始化
    self.speechRequest = [SFSpeechAudioBufferRecognitionRequest new];
    // 使用speechRequest请求进行识别
    self.currentSpeechTask =
    [self.speechRecognizer recognitionTaskWithRequest:self.speechRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result,NSError * _Nullable error)
     {
         // 识别结果，识别后的操作
         if (result == NULL) return;
         self.sTextView.text = result.bestTranscription.formattedString;
     }];
}

- (void)stopDictating
{
    // 停止声音处理器，停止语音识别请求进程
    [self.audioEngine stop];
    [self.speechRequest endAudio];
}

@end
