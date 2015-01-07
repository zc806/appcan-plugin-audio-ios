//
//  RecorderAmrController.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 12-5-14.
//  Copyright 2012 正益无线. All rights reserved.
//

#import "RecorderAmrController.h"
#import "EUtility.h"
#import "EUExAudio.h"
#import <QuartzCore/CALayer.h>
#import "EUExBaseDefine.h"

#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen] bounds].size.height-(double)568 ) < DBL_EPSILON )

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

@implementation RecorderAmrController
@synthesize startBtnIsSelected;
@synthesize useBtn,startBtn,playBtn;
@synthesize euexAudio;
@synthesize bgView,bottomBgView,statusView,bottomView,redCircleView,trendsImage,showTimeLabel,progressView;
@synthesize  savePath, saveNameStr, timeStr;
@synthesize delegate = _delegate;
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
-(void) audioRecordBegin {
	NSFileManager * fmanager = [NSFileManager defaultManager];
	if ([fmanager fileExistsAtPath:savePath]) {
		[fmanager removeItemAtPath:savePath error:nil];
	}
	PlayerManager * rManager = [PlayerManager getInstance];
	[rManager startRecord:savePath];
}

- (void)showTimer {
	second += 1;
	if (second == 60) {
		minute ++;
		second = 0;
	}
	if (minute == 60) {
		hours ++;
		minute = 0;
	}
	if (hours == 99) {
		hours = 0;
	}
	NSDateFormatter * df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"HH:mm:ss"];
	
    NSString * formatStr = [NSString stringWithFormat:@"%d:%d:%d",(int)hours,(int)minute,(int)second];
	NSDate * date = [df dateFromString:formatStr];
	NSString * str = [df stringFromDate:date];
	[df release];
	[showTimeLabel setText:str];
	self.timeStr = str;
	if (isRed) {
		[redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_off.png"]];
		isRed = NO;
	} else {
		[redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_on.png"]];
        isRed = YES;
	}
}

//获取当前时间字符串 //得到毫秒
- (NSString*)getCurrentTimeStr {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
	NSString *curTimeStr = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
	[dateFormatter release];
	return curTimeStr;
}

- (NSString *)getRecordFileName {
    NSString * wgtid = [EUtility brwViewWidgetId:euexAudio.meBrwView];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString * wgtPath = [paths objectAtIndex:0];
    NSString *recorderPath = [NSString stringWithFormat:@"%@/apps/%@/%@/",wgtPath,wgtid,RECORD_DOC_NAME];
	NSFileManager * fmanager = [NSFileManager defaultManager];
	if (![fmanager fileExistsAtPath:recorderPath]) {
		[fmanager createDirectoryAtPath:recorderPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
    NSString *fileName;
    if (self.saveNameStr) {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.amr",self.saveNameStr]];
    } else {
        fileName = [recorderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.amr",[self getCurrentTimeStr]]];
    }
	return fileName;
}

-(void)stopRecorder {
	[recordTimer invalidate];
	if (redCircleView) {
		[redCircleView removeFromSuperview];
	}
	if (showTimeLabel) {
		[showTimeLabel removeFromSuperview];
	}
	if (progressView) {
		[progressView removeFromSuperview];
	}
	UIProgressView *proV = [[UIProgressView alloc] initWithFrame:CGRectMake(32, 60, 244, 16)];
	proV.userInteractionEnabled = YES;
 	proV.progress = 0;
	self.progressView = proV;
	[proV release];
	[statusView addSubview:progressView];
	
	PlayerManager *pMgr = [PlayerManager getInstance];
	if (pMgr) {
		[pMgr stopRecord];
		hours = 0;
		minute = 0;
		second = 0;
	}
}
- (void)startRecord {
	[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
	
	if (redCircleView) {
		[redCircleView removeFromSuperview];
		[statusView addSubview:redCircleView];
	}
	if (showTimeLabel) {
		[showTimeLabel setText:@"00:00:00"];
		[showTimeLabel removeFromSuperview];
		[statusView addSubview:showTimeLabel];
	}
	if (progressView) {
		[progressView removeFromSuperview];
	}
	if (progressView) {
		progressView.progress = 0;
	}
	recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTimer) userInfo:nil repeats:YES];
 	[self audioRecordBegin];
}
-(long)getFileLength:(NSString *)fileName {
	NSFileManager * fmanager = [NSFileManager defaultManager];
	NSDictionary * dic = [fmanager attributesOfItemAtPath:fileName error:nil];
	NSNumber * fileSize = [dic objectForKey:NSFileSize];
	long sum = [fileSize longLongValue];
	return sum;
}
-(void)playRecord {
	if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
		//
	}
	recordFileLength = [self getFileLength:savePath];
	PlayerManager * pMgr = [PlayerManager getInstance];
	pMgr.playStatus = NO;
	pMgr.delegate = self;
	[pMgr playStop:savePath];
}
//-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
//	PluginLog(@"play success");
//	if (playBtn) {
//		[playBtn setSelected:NO];
//		[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
//
//	}
//}
-(void)stopPlay{
	if (playBtn) {
		[playBtn setSelected:NO];
		[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
	}
	PlayerManager *pMgr = [PlayerManager getInstance];
	if (pMgr) {
		[pMgr playStop:savePath];
	}
}
-(void)playBtnClick:(id)sender{
	UIButton * senderBtn = (UIButton *)sender;
	if ([senderBtn isSelected]) {
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
		[senderBtn setSelected:	NO];
 		[self stopPlay];
	} else {
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_narmal.png"] forState:UIControlStateNormal];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_focus.png"] forState:UIControlStateHighlighted];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/parse_disable.png"] forState:UIControlStateDisabled];
		[senderBtn setSelected:YES];
		[self playRecord];
	}
}
-(void)startBtnCick:(id)sender {
	minute = 0;
	second = 0;
	hours = 0;
	PlayerManager *pMgr = [PlayerManager getInstance];
	if ([pMgr playStatus] == YES) {
		[pMgr playStop:savePath];
	}
	UIButton * senderBtn = (UIButton *)sender;
	if ([senderBtn isSelected]) {
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
 		[useBtn setEnabled:YES];
		[playBtn setEnabled:YES];
		[senderBtn setSelected:	NO];
 		[self stopRecorder];
 	} else {
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_normal.png"] forState:UIControlStateNormal];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_pressed.png"] forState:UIControlStateHighlighted];
		[senderBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_stop_disabled.png"] forState:UIControlStateDisabled];
		[useBtn setEnabled:NO];
		[playBtn setEnabled:NO];
		[senderBtn setSelected:YES];
 		[self startRecord];
	}
}
-(void)useBtnClick:(id)sender {
	PlayerManager * pMgr = [PlayerManager getInstance];
	if ([pMgr playStatus] == YES) {
		[pMgr playStop:savePath];
 	}
	if ([pMgr recordStatus] == YES) {
		[pMgr stopRecord];
    }
    //设置返回路径
    if (euexAudio) {
        [euexAudio uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:savePath];
    }
	if (320 != SCREEN_WIDTH && [EUtility isIpad]) {
		if (_delegate && [_delegate respondsToSelector:@selector(closeRecorder)]) {
			[_delegate closeRecorder];
		}
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

-(void)closeBtnClick {
	PlayerManager *pMgr = [PlayerManager getInstance];
	if ([pMgr playStatus] == YES) {
		[pMgr playStop:savePath];
 	}
	if ([pMgr recordStatus] == YES) {
		[pMgr stopRecord];
	}
	if (320 != SCREEN_WIDTH && [EUtility isIpad]) {
		if (_delegate&&[_delegate respondsToSelector:@selector(closeRecorder)]) {
			[_delegate closeRecorder];
		}
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	//INIT TIME
	minute = 0;
	second = 0;
	hours = 0;
    self.savePath  = [self getRecordFileName];
	[self.view setBackgroundColor:[UIColor clearColor]];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(closeBtnClick)] autorelease];
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	//bg view
	UIImage * bguexAudio = [UIImage imageNamed:@"uexAudio/plugin_audio_recorder_bg.png"];
	bgView = [[UIImageView alloc] initWithImage:bguexAudio];
	[bgView setFrame:self.view.bounds];
	[bgView setUserInteractionEnabled:YES];
	[bgView setContentMode:UIViewContentModeScaleToFill];
	//status view;
	UIImage * statusViewuexAudio = [UIImage imageNamed:@"uexAudio/plugin_audio_recorder_center_bg.png"];
	statusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)];
	[statusView setImage:statusViewuexAudio];
	[statusView setUserInteractionEnabled:YES];
	//red circle
	redCircleView = [[UIImageView alloc] initWithFrame:CGRectMake(48, 40, 38, 38)];
	[redCircleView setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_turn_off.png"]];
	[statusView addSubview:redCircleView];
	//time view
	
	showTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 42, 190, 38)];
	[showTimeLabel setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:30]];
	[showTimeLabel setTextColor:[UIColor whiteColor]];
	[showTimeLabel setText:@" 00:00:00"];
	[showTimeLabel setBackgroundColor:[UIColor clearColor]];
	[statusView addSubview:showTimeLabel];
	
	//status image
	trendsImage = [[UIImageView alloc] initWithFrame:CGRectMake(30, 100, 250, 100)];
	[trendsImage setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_status.png"]];
	[statusView addSubview:trendsImage];
	[bgView addSubview:statusView];
	
	//bottom background
	UIImage  * dotImage = [UIImage imageNamed:@"uexAudio/plugin_audio_recorder_bg_dot.png"];
    float dotH = 198;
    if (IS_IPHONE_5) {
        dotH = 568 - 210 - 70;
    }
	bottomBgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 218, 320,dotH)];
	[bottomBgView setImage:dotImage];
    [bottomBgView setUserInteractionEnabled:YES];
	//bottomview
	bottomView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/footerbg.png"]];
	[bottomView setFrame:CGRectMake(0,bottomBgView.bounds.size.height - 50, 320, 50)];
	[bottomView setUserInteractionEnabled:YES];
	
	
	//play btn
	playBtn= [UIButton buttonWithType:UIButtonTypeCustom];
	[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
	[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_selected.png"] forState:UIControlStateHighlighted];
	[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_disabled.png"] forState:UIControlStateDisabled];
	[playBtn setFrame:CGRectMake(15, 0, 50, 50)];
	[playBtn setEnabled:NO];
	[playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
	[bottomView addSubview:playBtn];
	
	useBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_normal.png"] forState:UIControlStateNormal];
	[useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_pressed.png"] forState:UIControlStateHighlighted];
	[useBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_use_disabled.png"] forState:UIControlStateDisabled];
	[useBtn setFrame:CGRectMake(255, 0, 50, 50)];
	[useBtn setEnabled:NO];
	[useBtn addTarget:self action:@selector(useBtnClick:) forControlEvents:UIControlEventTouchUpInside];
	[bottomView addSubview:useBtn];
	
	//two lines
	UIImageView * imageLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/plugin_arrow_left.png"]];
	UIImageView * imageRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uexAudio/plugin_arrow_right.png"]];
	[imageLeft setFrame:CGRectMake(85, 0, 26, 50)];
	[imageRight setFrame:CGRectMake(209, 0, 26, 50)];
	[bottomView addSubview:imageLeft];
	[bottomView addSubview:imageRight];
	[imageRight release];
	[imageLeft release];
	
	//start btn
	startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_normal.png"] forState:UIControlStateNormal];
	[startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_pressed.png"] forState:UIControlStateHighlighted];
	[startBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_audio_recorder_record_disabled.png"] forState:UIControlStateDisabled];
	[startBtn setFrame:CGRectMake(135, 0, 50, 50)];
	[startBtn setEnabled:YES];
	[startBtn addTarget:self action:@selector(startBtnCick:) forControlEvents:UIControlEventTouchUpInside];
	[bottomView addSubview:startBtn];
	[bottomBgView addSubview:bottomView];
	[bgView addSubview:bottomBgView];
	[self.view addSubview:bgView];
}


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	trendsImage = nil;
	redCircleView = nil;
	bgView = nil;
	bottomView = nil;
	playBtn = nil;
	useBtn = nil;
	bottomBgView = nil;
	statusView = nil;
	startBtn = nil;
	showTimeLabel = nil;
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)changePlayProgressWithPro:(int)newProgress {
	if (recordFileLength == 0) {
		return;
	}
	float progress =  (newProgress*1.0)/recordFileLength;
	self.progressView.progress = progress;
}
-(void)playFinishedNotify{
	self.progressView.progress = 0;
	if (playBtn) {
		[playBtn setSelected:NO];
		[playBtn setImage:[UIImage imageNamed:@"uexAudio/plugin_video_play_normal.png"] forState:UIControlStateNormal];
		
	}
}
- (void)dealloc {
	[savePath release];
    if (self.saveNameStr) {
        self.saveNameStr = nil;
    }
	[trendsImage release];
	[redCircleView release];
	[bgView release];
	[bottomView release];
	[playBtn release];
	[useBtn release];
	[bottomBgView release];
	[statusView release];
	[euexAudio release];
	[startBtn release];
	[showTimeLabel release];
	[timeStr release];
    [super dealloc];
}


@end
