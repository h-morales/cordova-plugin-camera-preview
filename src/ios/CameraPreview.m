#import <AssetsLibrary/AssetsLibrary.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraPreview.h"

@implementation CameraPreview

- (void) startCamera:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera already started!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    return;
  }

  if (command.arguments.count > 3) {
    CGFloat x = (CGFloat)[command.arguments[0] floatValue] + self.webView.frame.origin.x;
    CGFloat y = (CGFloat)[command.arguments[1] floatValue] + self.webView.frame.origin.y;
    CGFloat width = (CGFloat)[command.arguments[2] floatValue];
    CGFloat height = (CGFloat)[command.arguments[3] floatValue];
    NSString *defaultCamera = command.arguments[4];
    BOOL tapToTakePicture = (BOOL)[command.arguments[5] boolValue];
    BOOL dragEnabled = (BOOL)[command.arguments[6] boolValue];
    BOOL toBack = (BOOL)[command.arguments[7] boolValue];
    // Create the session manager
    self.sessionManager = [[CameraSessionManager alloc] init];

    //render controller setup
    self.cameraRenderController = [[CameraRenderController alloc] init];
    self.cameraRenderController.dragEnabled = dragEnabled;
    self.cameraRenderController.tapToTakePicture = tapToTakePicture;
    self.cameraRenderController.sessionManager = self.sessionManager;
    self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);
    self.cameraRenderController.delegate = self;

    [self.viewController addChildViewController:self.cameraRenderController];
    //display the camera bellow the webview
    if (toBack) {
      //make transparent
      self.webView.opaque = NO;
      self.webView.backgroundColor = [UIColor clearColor];
      [self.webView.superview insertSubview:self.cameraRenderController.view belowSubview:self.webView];
    }
    else{
      self.cameraRenderController.view.alpha = (CGFloat)[command.arguments[8] floatValue];
      [self.webView.superview insertSubview:self.cameraRenderController.view aboveSubview:self.webView];
    }

    // Setup session
    self.sessionManager.delegate = self.cameraRenderController;
    [self.sessionManager setupSession:defaultCamera];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"stopCamera");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil) {
    [self.cameraRenderController.view removeFromSuperview];
    [self.cameraRenderController removeFromParentViewController];
    self.cameraRenderController = nil;

    [self.sessionManager.session stopRunning];
    self.sessionManager = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  }
  else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) hideCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"hideCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:YES];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) showCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"showCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:NO];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) switchCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"switchCamera");
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    [self.sessionManager switchCamera];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFlashMode:(CDVInvokedUrlCommand*)command {
  NSLog(@"Flash Mode");
  CDVPluginResult *pluginResult;

  NSInteger flashMode;
  NSString *errMsg;

  if (command.arguments.count <= 0)
  {
    errMsg = @"Please specify a flash mode";
  }
  else
  {
    NSString *strFlashMode = [command.arguments objectAtIndex:0];
    flashMode = [strFlashMode integerValue];
    if (flashMode != AVCaptureFlashModeOff
        && flashMode != AVCaptureFlashModeOn
        && flashMode != AVCaptureFlashModeAuto)
    {
      errMsg = @"Invalid parameter";
    }

  }

  if (errMsg) {
    NSLog(@"%@", errMsg);

  } else {
    if (self.sessionManager != nil) {
      [self.sessionManager setFlashMode:flashMode];
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) takePicture:(CDVInvokedUrlCommand*)command {
  NSLog(@"takePicture");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != NULL) {
    CGFloat maxW = (CGFloat)[command.arguments[0] floatValue];
    CGFloat maxH = (CGFloat)[command.arguments[1] floatValue];
    [self invokeTakePicture:maxW withHeight:maxH];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

-(void) setOnPictureTakenHandler:(CDVInvokedUrlCommand*)command {
  NSLog(@"setOnPictureTakenHandler");
  self.onPictureTakenHandlerId = command.callbackId;
}

-(void) setColorEffect:(CDVInvokedUrlCommand*)command {
  NSLog(@"setColorEffect");
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  NSString *filterName = command.arguments[0];

  if ([filterName isEqual: @"none"]) {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        [self.sessionManager setCiFilter:nil];
        });
  } else if ([filterName isEqual: @"mono"]) {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
        [filter setDefaults];
        [self.sessionManager setCiFilter:filter];
        });
  } else if ([filterName isEqual: @"negative"]) {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
        [filter setDefaults];
        [self.sessionManager setCiFilter:filter];
        });
  } else if ([filterName isEqual: @"posterize"]) {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        CIFilter *filter = [CIFilter filterWithName:@"CIColorPosterize"];
        [filter setDefaults];
        [self.sessionManager setCiFilter:filter];
        });
  } else if ([filterName isEqual: @"sepia"]) {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
        [filter setDefaults];
        [self.sessionManager setCiFilter:filter];
        });
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Filter not found"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void) getSupportedPreviewSizes:(CDVInvokedUrlCommand*)command {
  NSLog(@"getSupportedPreviewSizes");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil){
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"universal"];
  }
  else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void) getSupportedPictureSizes:(CDVInvokedUrlCommand*)command {
  NSLog(@"getSupportedPictureSizes");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil){
    NSArray *formats = self.sessionManager.getDeviceFormats;
    NSMutableArray *jsonFormats = [NSMutableArray new];
    int lastWidth = 0;
    int lastHeight = 0;
    for (AVCaptureDeviceFormat *format in formats) {
      CMVideoDimensions dim = format.highResolutionStillImageDimensions;
      if (dim.width!=lastWidth && dim.height != lastHeight) {
        NSMutableDictionary *dimensions = [[NSMutableDictionary alloc] init];
        NSNumber *width = [NSNumber numberWithInt:dim.width];
        NSNumber *height = [NSNumber numberWithInt:dim.height];
        [dimensions setValue:width forKey:@"width"];
        [dimensions setValue:height forKey:@"height"];
        [jsonFormats addObject:dimensions];
        lastWidth = dim.width;
        lastHeight = dim.height;
      }
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:jsonFormats];

  }
  else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) invokeTakePicture {
  [self invokeTakePicture:0.0 withHeight:0.0];
}

- (NSString *)getBase64Image:(CGImageRef)imageRef {
  NSString *base64Image = nil;

  @try {
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    base64Image = [imageData base64EncodedStringWithOptions:0];
  }
  @catch (NSException *exception) {
    NSLog(@"error while get base64Image: %@", [exception reason]);
  }

  return base64Image;
}

- (double)radiansFromUIImageOrientation:(UIImageOrientation)orientation
{
  double radians;

  switch (orientation) {
      case UIImageOrientationUp :
          radians = 0.0;
          break;
          
      case UIImageOrientationDown:
          radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
          break;
          
      case UIImageOrientationRight:
          radians = M_PI_2;
          break;
          
      case UIImageOrientationLeft:
          radians = -M_PI_2;
          break;
  }

  return radians;
}

-(CGImageRef) CGImageRotated:(CGImageRef) originalCGImage withRadiants:(double) radians
{
  CGSize imageSize = CGSizeMake(CGImageGetWidth(originalCGImage), CGImageGetHeight(originalCGImage));
  CGSize rotatedSize;
  if (radians == M_PI_2 || radians == -M_PI_2) {
    rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
  } else {
    rotatedSize = imageSize;
  }

  double rotatedCenterX = rotatedSize.width / 2.f;
  double rotatedCenterY = rotatedSize.height / 2.f;

  UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
  CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
  if (radians == 0.f || radians == M_PI) { // 0 or 180 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    if (radians == 0.0f) {
      CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    } else {
      CGContextScaleCTM(rotatedContext, -1.f, 1.f);
    }
    CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
  } else if (radians == M_PI_2 || radians == -M_PI_2) { // +/- 90 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    CGContextRotateCTM(rotatedContext, radians);
    CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
  }

  CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
  CGContextDrawImage(rotatedContext, drawingRect, originalCGImage);
  CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);

  UIGraphicsEndImageContext();
  CFAutorelease((CFTypeRef)rotatedCGImage);

  return rotatedCGImage;
}

- (void) invokeTakePicture:(CGFloat) maxWidth withHeight:(CGFloat) maxHeight {
    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {

      NSLog(@"Done creating still image");

      if (error) {
        NSLog(@"%@", error);
      } else {


        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
        UIImage *capturedImage  = [[UIImage alloc] initWithData:imageData];

        CIImage *capturedCImage;
        //image resize

        if(maxWidth > 0 && maxHeight > 0){
          CGFloat scaleHeight = maxWidth/capturedImage.size.height;
          CGFloat scaleWidth = maxHeight/capturedImage.size.width;
          CGFloat scale = scaleHeight > scaleWidth ? scaleWidth : scaleHeight;

          CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
          [resizeFilter setValue:[[CIImage alloc] initWithCGImage:[capturedImage CGImage]] forKey:kCIInputImageKey];
          [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
          [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
          capturedCImage = [resizeFilter outputImage];
        }
        else{
          capturedCImage = [[CIImage alloc] initWithCGImage:[capturedImage CGImage]];
        }

        CIImage *imageToFilter;
        CIImage *finalCImage;

        //fix front mirroring
        if (self.sessionManager.defaultCamera == AVCaptureDevicePositionFront) {
          CGAffineTransform matrix = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, capturedCImage.extent.size.height);
          imageToFilter = [capturedCImage imageByApplyingTransform:matrix]; 
        } else {
          imageToFilter = capturedCImage;                    
        }

        CIFilter *filter = [self.sessionManager ciFilter];
        if (filter != nil) {
          [self.sessionManager.filterLock lock];
          [filter setValue:imageToFilter forKey:kCIInputImageKey];
          finalCImage = [filter outputImage];
          [self.sessionManager.filterLock unlock];
        } else {
          finalCImage = imageToFilter;
        }

        CGImageRef finalImage = [self.cameraRenderController.ciContext createCGImage:finalCImage fromRect:finalCImage.extent];


        dispatch_group_t group = dispatch_group_create();


        ALAssetOrientation orientation;
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
          case UIDeviceOrientationPortraitUpsideDown:
            orientation = ALAssetOrientationLeft;
            break;
          case UIDeviceOrientationLandscapeLeft:
            orientation = ALAssetOrientationUp;
            break;
          case UIDeviceOrientationLandscapeRight:
            orientation = ALAssetOrientationDown;
            break;
          case UIDeviceOrientationPortrait:
                                   default:
            orientation = ALAssetOrientationRight;
        }

        

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableArray *params = [[NSMutableArray alloc] init];
          
            // Success returns two elements in the returned array
            
            UIImage *resultImage = [UIImage imageWithCGImage:finalImage];
            double radiants = [self radiansFromUIImageOrientation:resultImage.imageOrientation];
            CGImageRef resultFinalImage = [self CGImageRotated:finalImage withRadiants:radiants];

            NSString *base64Image = [self getBase64Image:resultFinalImage];
            [params addObject:base64Image];
            

            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
        });
      }
    }];
}
@end
