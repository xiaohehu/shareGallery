//
//  ViewController.m
//  shareGallery
//
//  Created by Xiaohe Hu on 2/5/15.
//  Copyright (c) 2015 Neoscape. All rights reserved.
//

#import "ViewController.h"
#import "galleryCell.h"
#import "XHGalleryViewController.h"
#import "embEmailData.h"
#import <MessageUI/MessageUI.h>

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, XHGalleryDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    NSArray             *arr_rawData;
    CGRect              viewFrame;
    NSMutableArray      *arr_data;
    NSMutableArray      *arr_selectedCells;
    BOOL                enabledShare;
    
    UIView              *uiv_shareControlContainer;
}
@property (nonatomic, strong)   XHGalleryViewController *gallery;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *uib_share;
@end

@implementation ViewController
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initData];
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"theCell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor redColor];
    [_collectionView reloadData];
    [self initShareControlPanel];

    [self prepareGalleryData];
}

- (void)viewDidAppear:(BOOL)animated
{
    viewFrame = self.view.bounds;
}

- (void)initData
{
    arr_data = [NSMutableArray array];
    for (int i = 0 ; i < 32; i++) {
        [arr_data addObject: [NSString stringWithFormat:@"%i", i]];
    }
    arr_selectedCells = [NSMutableArray array];
    
//    NSLog(@"%@", arr_data);
}

- (void)initShareControlPanel
{
//    uiv_shareControlContainer = [UIView new];
    uiv_shareControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.bounds.size.height - 100, self.view.bounds.size.width, 100)];
    uiv_shareControlContainer.backgroundColor = [UIColor grayColor];
    [self.view addSubview: uiv_shareControlContainer];
    uiv_shareControlContainer.transform = CGAffineTransformMakeTranslation(0.0, uiv_shareControlContainer.frame.size.height);
    
//    // Size contstraints
//    NSArray *control_constraint_H = [NSLayoutConstraint
//                                     constraintsWithVisualFormat:@"V:[uiv_shareControlContainer(100)]"
//                                     options:0
//                                     metrics:nil
//                                     views:NSDictionaryOfVariableBindings(uiv_shareControlContainer)];
//    
//    NSArray *control_constraint_V = [NSLayoutConstraint
//                                     constraintsWithVisualFormat:@"H:|[uiv_shareControlContainer]|"
//                                     options:0
//                                     metrics:nil
//                                     views:NSDictionaryOfVariableBindings(uiv_shareControlContainer)];
//    [self.view addConstraints: control_constraint_H];
//    [self.view addConstraints: control_constraint_V];
//
//    // Position constraints
//    NSArray *constraints = [NSLayoutConstraint
//                            constraintsWithVisualFormat:@"V:[uiv_shareControlContainer]-offsetBtm-|"
//                            options:0
//                            metrics:@{@"offsetBtm": @0}
//                            views:NSDictionaryOfVariableBindings(uiv_shareControlContainer)];
//    
//    [self.view addConstraints: constraints];
    
    [self createControlBtns];
}

- (void)createControlBtns
{
    UIButton *uib_done = [UIButton buttonWithType:UIButtonTypeCustom];
    uib_done.frame = CGRectMake(uiv_shareControlContainer.bounds.size.width - 100 - 20, (uiv_shareControlContainer.bounds.size.height -  30)/2, 100, 30);
    uib_done.backgroundColor = [UIColor whiteColor];
    [uib_done setTitle:@"Done" forState:UIControlStateNormal];
    [uib_done setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    uib_done.highlighted = YES;
    [uiv_shareControlContainer addSubview: uib_done];
    [uib_done addTarget:self action:@selector(tapDoneBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *uib_email = [UIButton buttonWithType:UIButtonTypeCustom];
    uib_email.frame = CGRectMake(20.0, 10.0, 100.0, 30.0);
    [uib_email setTitle:@"Eamil" forState:UIControlStateNormal];
    uib_email.backgroundColor = [UIColor whiteColor];
    [uib_email setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [uiv_shareControlContainer addSubview: uib_email];
    [uib_email addTarget:self action:@selector(emailData) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *uib_pdf = [UIButton buttonWithType:UIButtonTypeCustom];
    uib_pdf.frame = CGRectMake(20.0, 60.0, 100.0, 30.0);
    [uib_pdf setTitle:@"PDF" forState:UIControlStateNormal];
    uib_pdf.backgroundColor = [UIColor whiteColor];
    [uib_pdf setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [uiv_shareControlContainer addSubview: uib_pdf];
}

- (void)tapDoneBtn:(id)sender
{
    [UIView animateWithDuration:0.33 animations:^{
        uiv_shareControlContainer.transform = CGAffineTransformMakeTranslation(0.0, uiv_shareControlContainer.frame.size.height);
    }];
    _uib_share.enabled = YES;
    _collectionView.allowsMultipleSelection = NO;
    [_collectionView reloadData];
}

- (IBAction)shareBtnTapped:(id)sender {
    _uib_share.enabled = NO;
    enabledShare = YES;
    _collectionView.allowsMultipleSelection = YES;
    [_collectionView reloadData];
    [UIView animateWithDuration:0.33 animations:^{
        uiv_shareControlContainer.transform = CGAffineTransformIdentity;
    }];
}

- (void)prepareGalleryData
{
    NSString *url = [[NSBundle mainBundle] pathForResource:@"photoData" ofType:@"plist"];
    arr_rawData = [[NSArray alloc] initWithContentsOfFile:url];
}

/*
 *To make sure the frame correct under iOS7,
 *Call thre createGallery method in ViewDidAppear:
 */
- (void)createGallery:(int)startIndex
{
    _gallery = [[XHGalleryViewController alloc] init];
    _gallery.delegate = self;
    _gallery.startIndex = startIndex;
    _gallery.view.frame = viewFrame;
    _gallery.arr_rawData = [arr_rawData objectAtIndex:0];
//    _gallery.view.frame = CGRectMake(0.0, 0.0, 400, 300);
//    _gallery.showNavBar = NO;
//    _gallery.showCaption = NO
}

//----------------------------------------------------
#pragma mark Remove gallery delegate
//----------------------------------------------------
- (void)didRemoveFromSuperView
{
    [UIView animateWithDuration:0.33
                     animations:^{
                         _gallery.view.alpha = 0.0;
                     } completion:^(BOOL finshed){
                         [_gallery.view removeFromSuperview];
                         _gallery.view = nil;
                         [_gallery removeFromParentViewController];
                         _gallery = nil;
                         [_collectionView reloadData];
                     }];
}

#pragma mark - Collection Delegate Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 32;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    galleryCell *galleryImageCell = [collectionView
                                    dequeueReusableCellWithReuseIdentifier:@"theCell"
                                    forIndexPath:indexPath];
    
    galleryImageCell.backgroundColor = [UIColor whiteColor];

    UIView *selectedView = [[UIView alloc] initWithFrame:galleryImageCell.bounds];
    selectedView.backgroundColor = [UIColor blueColor];
    galleryImageCell.selectedBackgroundView = selectedView;
//    [galleryImageCell.cellContent setText:@"test"];
    return galleryImageCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (enabledShare) {
        // Get the selected string
        NSString *theNum = [arr_data objectAtIndex:indexPath.item];
        // Add the selected item to the array
        [arr_selectedCells addObject: theNum];
//        NSLog(@"\n\n %@", arr_selectedCells);
    }
    else
    {
        [self createGallery:0];
        [self addChildViewController:_gallery];
        [self.view addSubview: _gallery.view];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (enabledShare) {
        // Get the selected string
        NSString *theNum = [arr_data objectAtIndex:indexPath.item];
        // Remove the selected item to the array
        [arr_selectedCells removeObject: theNum];
    }
    
}

#pragma mark Email Selected Array after formatting
-(IBAction)finishedSelectingItemsForEmail:(id)sender
{
//    UIButton*selectedBtn = (UIButton*)sender;
//    BOOL isPDF;
//    
//    if (selectedBtn.tag == 110) {
//        isPDF = YES;
//    } else{
//        isPDF = NO;
//    }
//    
//    NSLog(@"Finished Selecting");
//    
//    selectedArray = [[selectedIndexPaths valueForKey:@"fileName"] mutableCopy];
//    
//    NSString	*justFileName;
//    NSString	*webLinkBody;
//    NSArray		*attachmentData;
//    
//    // web text, if any
//    NSMutableString *formattedWeb = [self formatWebLinks];
//    
//    if ([_uitf_name.text length] == 0) {
//        greetingName = [NSString stringWithFormat:@"."];
//    } else {
//        greetingName = [NSString stringWithFormat:@", %@", _uitf_name.text];
//    }
//    
//    webLinkBody = [NSString stringWithFormat:@"Thank you for visiting our Sales Center%@<br /><br />%@", greetingName,formattedWeb];
//    
//    if (isPDF) {
//        // inserted cover page to array
//        justFileName = @"Brochure_Cover_Page_01";
//        [selectedArray insertObject:justFileName atIndex:0];
//        
//        // pdf creation
//        [self setupPDFDocumentNamed:@"Demo" Width:1100 Height:850];
//        
//        // remove any other pdfs temporarily
//        NSMutableArray *tempRemovePDFS = [NSMutableArray array];
//        for (id file in selectedArray) {
//            if ([[file pathExtension] isEqualToString:@"pdf"]) {
//                [tempRemovePDFS addObject:file];
//                NSLog(@"removed: %@", file);
//            }
//        }
//        [selectedArray removeObjectsInArray:tempRemovePDFS];
//        
//        // pdf data
//        [self addDataToPDF:selectedArray];
//        
//        // close & save pdf
//        [self finishAndSavePDF];
//        
//        // get newly saved pdf from documents directory and send
//        NSData *pdfData = [self getPDFAsNSDataNamed:@"Demo.pdf"];
//        NSMutableArray*attachData = [[NSMutableArray alloc] initWithObjects:pdfData, nil];
//        
//        // remove anything already added to the created pdf
//        // remove cover image
//        [selectedArray removeObjectAtIndex:0];
//        
//        // remove any other images from array
//        NSMutableArray *tooDelete = [NSMutableArray array];
//        for (id file in selectedArray) {
//            if ([[file pathExtension] isEqualToString:@"jpg"]) {
//                [tooDelete addObject:file];
//                NSLog(@"removed: %@", file);
//            }
//        }
//        
//        [selectedArray removeObjectsInArray:tooDelete];
//        
//        // add BACK in any added pdfs
//        [attachData addObjectsFromArray:tempRemovePDFS];
//        
//        // prepare final array to send to email,
//        [attachData addObjectsFromArray:selectedArray];
//        attachmentData = [NSArray arrayWithArray:attachData];
//        
//    } else {
//        attachmentData = selectedArray;
//    }
//    
//    [self dismissViewControllerAnimated:YES completion:^{
//        embEmailData *emailData = [[embEmailData alloc] init];
//        //emailData.to = @[@"evan.buxton@neoscape.com"];
//        emailData.subject = @"Skanska 101 Seaport Marketing Package";
//        emailData.body = webLinkBody;
//        emailData.attachment = attachmentData;
//        emailData.optionsAlert=NO;
//        [self dismissVC:nil];
//    }];
    
}

-(void)emailData
{
    embEmailData *emailData = [[embEmailData alloc] init];
    emailData.optionsAlert=NO;
    
    if ([MFMailComposeViewController canSendMail] == YES) {
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self; // &lt;- very important step if you want feedbacks on what the user did with your email sheet
        
        if(emailData.to)
            [picker setToRecipients:emailData.to];
        
        if(emailData.cc)
            [picker setCcRecipients:emailData.cc];
        
        if(emailData.bcc)
            [picker setBccRecipients:emailData.bcc];
        
        if(emailData.subject)
            [picker setSubject:emailData.subject];
        
        if(emailData.body)
            [picker setMessageBody:emailData.body isHTML:YES]; // depends. Mostly YES, unless you want to send it as plain text (boring)
        
        // attachment code
        if(emailData.attachment) {
            
            NSString	*filePath;
            NSString	*justFileName;
            NSData		*myData;
            UIImage		*pngImage;
            NSString	*newname;
            
            for (id file in emailData.attachment)
            {
                // check if it is a uiimage and handle
                if ([file isKindOfClass:[UIImage class]]) {
                    
                    myData = UIImagePNGRepresentation(file);
                    [picker addAttachmentData:myData mimeType:@"image/png" fileName:@"image.png"];
                    
                    // might be nsdata for pdf
                } else if ([file isKindOfClass:[NSData class]]) {
                    NSLog(@"pdf");
                    myData = [NSData dataWithData:file];
                    NSString *mimeType;
                    mimeType = @"application/pdf";
                    newname = @"Brochure.pdf";
                    [picker addAttachmentData:myData mimeType:mimeType fileName:newname];
                    
                    // it must be another file type?
                } else {
                    
                    justFileName = [[file lastPathComponent] stringByDeletingPathExtension];
                    
                    NSString *mimeType;
                    // Determine the MIME type
                    if ([[file pathExtension] isEqualToString:@"jpg"]) {
                        mimeType = @"image/jpeg";
                    } else if ([[file pathExtension] isEqualToString:@"png"]) {
                        mimeType = @"image/png";
                        pngImage = [UIImage imageNamed:file];
                    } else if ([[file pathExtension] isEqualToString:@"doc"]) {
                        mimeType = @"application/msword";
                    } else if ([[file pathExtension] isEqualToString:@"ppt"]) {
                        mimeType = @"application/vnd.ms-powerpoint";
                    } else if ([[file pathExtension] isEqualToString:@"html"]) {
                        mimeType = @"text/html";
                    } else if ([[file pathExtension] isEqualToString:@"pdf"]) {
                        mimeType = @"application/pdf";
                    } else if ([[file pathExtension] isEqualToString:@"com"]) {
                        mimeType = @"text/plain";
                    }
                    
                    filePath= [[NSBundle mainBundle] pathForResource:justFileName ofType:[file pathExtension]];
                    
                    if (![[file pathExtension] isEqualToString:@"png"]) {
                        myData = [NSData dataWithContentsOfFile:filePath];
                        myData = [NSData dataWithContentsOfFile:filePath];
                    } else {
                        myData = UIImagePNGRepresentation(pngImage);
                    }
                    
                    newname = file;
                    [picker addAttachmentData:myData mimeType:mimeType fileName:newname];
                }
            }
        }
        
        picker.navigationBar.barStyle = UIBarStyleBlack; // choose your style, unfortunately, Translucent colors behave quirky.
        [self presentViewController:picker animated:YES completion:nil];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status" message:[NSString stringWithFormat:@"Email needs to be configured before this device can send email. \n\n Use support@neoscape.com on a device capable of sending email."]
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank you!" message:@"Email Sent Successfully"
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
            break;
        case MFMailComposeResultFailed:
            break;
            
        default:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Status" message:@"Sending Failed - Unknown Error"
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    NSLog(@"FINISHED");
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
