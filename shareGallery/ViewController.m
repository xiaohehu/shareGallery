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
#import "SmallAlbumCollectionViewController.h"
#import "UIImage+ScaleToFit.h"

@interface ViewController ()
<
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    XHGalleryDelegate,
    MFMessageComposeViewControllerDelegate,
    MFMailComposeViewControllerDelegate,
    UIPopoverControllerDelegate
>

{
    NSArray             *arr_rawData;
    CGRect              viewFrame;
    NSMutableArray      *arr_selectedCells;
    BOOL                enabledShare;
    BOOL                creatPDF;
    UIView              *uiv_shareControlContainer;
    
    CGSize				_pageSize;
    NSMutableArray		*filesInPDF;
    NSMutableArray		*bytesInPDF;
    NSMutableArray      *selectedBytes;
    UILabel             *uil_size;
    UILabel             *uil_10mb;
    UIView              *upperRect;
    UIView              *lowerRect;
    CGFloat             totalBhytes;
    NSNumber            *byt;
}
@property (nonatomic, strong)       XHGalleryViewController                 *gallery;
@property (weak, nonatomic)         IBOutlet UICollectionView               *collectionView;
@property (weak, nonatomic)         IBOutlet UIButton                       *uib_share;
@property (nonatomic, strong)       SmallAlbumCollectionViewController      *smallAlbum;
@property (nonatomic, strong)       UIPopoverController                     *smallAlbumPopover;
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

    [self prepareGalleryData];
}

- (void)viewDidAppear:(BOOL)animated
{
    viewFrame = self.view.bounds;
    [self initShareControlPanel];
}

- (void)initData
{
    filesInPDF          = [[NSMutableArray alloc] init];
    bytesInPDF          = [[NSMutableArray alloc] init];
    arr_selectedCells   = [[NSMutableArray array] init];
    selectedBytes       = [[NSMutableArray alloc] init];
    
    upperRect           = [[UIView alloc] init];
    lowerRect           = [[UIView alloc] init];
}

#pragma mark - Bytes

-(void)updateProgress
{
    float percentDone = 0;
    UIColor *spaceleft = [UIColor yellowColor];
    if ((totalBhytes/1000 > 500) && (totalBhytes/1000 < 2500)) {
        percentDone = .20;
    } else if ((totalBhytes/1000 > 2500) && (totalBhytes/1000 < 5000)) {
        percentDone = .40;
    } else if ((totalBhytes/1000 > 5000) && (totalBhytes/1000 < 7500)) {
        percentDone = .60;
    } else if ((totalBhytes/1000 > 7500) && (totalBhytes/1000 < 10000)) {
        percentDone = .80;
        spaceleft = [UIColor redColor];
    } else if ((totalBhytes/1000 > 10000)) {
        spaceleft = [UIColor redColor];
        percentDone = 1;
    }
    
    NSLog(@"percentDone: %f",percentDone);
    
    CGRect rect = CGRectMake(260, 70, 150, 5);
    
    upperRect.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width * percentDone, rect.size.height );
    
    lowerRect.frame = CGRectMake(rect.origin.x + (rect.size.width * percentDone), rect.origin.y, rect.size.width*(1-percentDone), rect.size.height );
    lowerRect.alpha = 0.7;
    upperRect.alpha = 0.7;
    
    [upperRect setBackgroundColor:spaceleft];
    [lowerRect setBackgroundColor:[UIColor greenColor]];
    
    [uiv_shareControlContainer insertSubview:upperRect atIndex:1];
    [uiv_shareControlContainer insertSubview:lowerRect atIndex:1];
    
    NSString *sttring = [NSByteCountFormatter stringFromByteCount:totalBhytes countStyle:NSByteCountFormatterCountStyleFile];
    
    uil_size.text = [NSString stringWithFormat:@"Size: %@",sttring];
}

-(CGFloat)byteSizeOfFile:(NSString *)linkText
{
    NSData			*imgData;
    UIImage			*pngImage;
    
    // if cell == existing documents, calculate that size
    if ([linkText isEqualToString:@"Floorplans.pdf"]) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:linkText ofType:nil];
        imgData = [NSData dataWithContentsOfFile:imagePath];
    } else {
        NSString *justFileName = [[linkText lastPathComponent] stringByDeletingPathExtension];
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:justFileName ofType:@"jpg"];
        pngImage = [UIImage imageWithImage:[UIImage imageWithContentsOfFile:imagePath] scaledToWidth:1100];
        UIImage *t = [UIImage imageWithContentsOfFile:imagePath];
        imgData = UIImagePNGRepresentation(t);
    }
    
    CGFloat bytesString = [imgData length];
    
    return bytesString;
}

-(void)updateTotalBytes
{
    if (bytesInPDF) {
        [bytesInPDF removeAllObjects];
        totalBhytes=0;
    }
    
    [bytesInPDF addObjectsFromArray:selectedBytes];
    NSLog(@"\n\n %@", bytesInPDF);
    for (NSNumber *t in bytesInPDF) {
        totalBhytes = totalBhytes+[t intValue];
    }
    
    [self updateProgress];
//    NSLog(@"totalBhytes %f",totalBhytes/1000);
}

//----------------------------------------------------
#pragma mark - Share control Panel setting and action
//----------------------------------------------------

- (void)initShareControlPanel
{
    uiv_shareControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.bounds.size.height - 100, self.view.bounds.size.width, 100)];
    uiv_shareControlContainer.backgroundColor = [UIColor grayColor];
    [self.view addSubview: uiv_shareControlContainer];
    uiv_shareControlContainer.transform = CGAffineTransformMakeTranslation(0.0, uiv_shareControlContainer.frame.size.height);
    
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
    uib_email.tag = 10;
    [uib_email setTitle:@"Eamil" forState:UIControlStateNormal];
    uib_email.backgroundColor = [UIColor whiteColor];
    [uib_email setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [uiv_shareControlContainer addSubview: uib_email];
    [uib_email addTarget:self action:@selector(emailData:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *uib_pdf = [UIButton buttonWithType:UIButtonTypeCustom];
    uib_pdf.frame = CGRectMake(20.0, 60.0, 100.0, 30.0);
    uib_pdf.tag = 11;
    [uib_pdf setTitle:@"PDF" forState:UIControlStateNormal];
    uib_pdf.backgroundColor = [UIColor whiteColor];
    [uib_pdf setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [uiv_shareControlContainer addSubview: uib_pdf];
    [uib_pdf addTarget:self action:@selector(emailData:) forControlEvents:UIControlEventTouchUpInside];
    
    uil_size = [[UILabel alloc] initWithFrame:CGRectMake(160, 60, 150, 20)];
    uil_size.text = @"Size: ";
    [uil_size setFont:[UIFont systemFontOfSize:15]];
    uil_size.textColor = [UIColor blackColor];
    uil_size.textAlignment = NSTextAlignmentLeft;
    [uiv_shareControlContainer addSubview: uil_size];
    
    uil_10mb = [[UILabel alloc] initWithFrame:CGRectMake(350, 60.0, 150, 20)];
    [uiv_shareControlContainer addSubview: uil_10mb];
    uil_10mb.text = @"10MBs";
    uil_10mb.textColor =[UIColor blackColor];
    uil_10mb.textAlignment = NSTextAlignmentRight;
    uil_10mb.font = [UIFont systemFontOfSize:15];
}

- (void)tapDoneBtn:(id)sender
{
    [UIView animateWithDuration:0.33 animations:^{
        uiv_shareControlContainer.transform = CGAffineTransformMakeTranslation(0.0, uiv_shareControlContainer.frame.size.height);
    }];
    _uib_share.enabled = YES;
    enabledShare = NO;
    _collectionView.allowsMultipleSelection = NO;
    [_collectionView reloadData];
    [_collectionView reloadData];
    [arr_selectedCells removeAllObjects];
    [bytesInPDF removeAllObjects];
    [filesInPDF removeAllObjects];
    [selectedBytes removeAllObjects];
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

//----------------------------------------------------
#pragma mark - Init Gallery
//----------------------------------------------------
- (void)prepareGalleryData
{
    NSString *url = [[NSBundle mainBundle] pathForResource:@"photoData" ofType:@"plist"];
    arr_rawData = [[NSArray alloc] initWithContentsOfFile:url];
//    NSLog(@"the photos are %@", arr_rawData);
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

//----------------------------------------------------
#pragma mark - Collection Delegate Methods
//----------------------------------------------------
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
    return galleryImageCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGRect cellRect = attributes.frame;
    CGRect frame = [collectionView convertRect:cellRect toView:self.view];
    NSLog(@"The selected cell is %@", NSStringFromCGRect(frame));
    
    
    if (enabledShare) {
        // First item of gallery is an album
        if (indexPath.item > 0) {
            // Get the selected string
            NSString *theNum = @"Lobby View.jpg";
            // Add the selected item to the array
            [arr_selectedCells addObject: theNum];
            byt = [NSNumber numberWithFloat:[self byteSizeOfFile:theNum]];
            [selectedBytes addObject:byt];
            [self updateTotalBytes];
        }
        else {
            if (_smallAlbum == nil) {
                UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
                [aFlowLayout setItemSize:CGSizeMake(50, 50)];
                [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
                _smallAlbum = [[SmallAlbumCollectionViewController alloc]initWithCollectionViewLayout:aFlowLayout];
            }
            
            _smallAlbumPopover = [[UIPopoverController alloc] initWithContentViewController:_smallAlbum];
            [_smallAlbumPopover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            _smallAlbumPopover.delegate = self;
        }

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
        [arr_selectedCells removeLastObject];
    }
}

//----------------------------------------------------
#pragma mark - Generate email
//----------------------------------------------------
-(void)emailData:(id)sender
{
    if (arr_selectedCells.count == 0) {
        NSLog(@"\n\n Load blank email!");
        return;
    }
    embEmailData *emailData = [[embEmailData alloc] init];
    if ([sender tag] == 11)
    {
        emailData.attachment = [self createPdfAttachment];
        emailData.optionsAlert=NO;
    }
    else
    {
//        embEmailData *emailData = [[embEmailData alloc] init];
        emailData.attachment = arr_selectedCells;
        emailData.optionsAlert=NO;
    }
    
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
                    NSLog(@"The file's name is \n%@", newname);
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
    [_collectionView reloadData];
    [arr_selectedCells removeAllObjects];
    [bytesInPDF removeAllObjects];
    [filesInPDF removeAllObjects];
    [selectedBytes removeAllObjects];
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    NSLog(@"FINISHED");
}

//----------------------------------------------------
#pragma mark - PopOver Delegate
//----------------------------------------------------
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"Should get data back from small album");
    [arr_selectedCells addObjectsFromArray:[_smallAlbum getSelectedItem]];
    totalBhytes = totalBhytes + [_smallAlbum getSelectedItemSize];
    [self updateProgress];
    _smallAlbumPopover = nil;
    [_smallAlbum.view removeFromSuperview];
    [_smallAlbum removeFromParentViewController];
    _smallAlbum = nil;
}

//----------------------------------------------------
#pragma mark - pdf creation
//----------------------------------------------------
- (NSArray *)createPdfAttachment
{
    // pdf creation
    [self setupPDFDocumentNamed:@"Demo" Width:1100 Height:850];
    
    // remove any other pdfs temporarily
    NSMutableArray *tempRemovePDFS = [NSMutableArray array];
    for (id file in arr_selectedCells) {
        if ([[file pathExtension] isEqualToString:@"pdf"]) {
            [tempRemovePDFS addObject:file];
            NSLog(@"removed: %@", file);
        }
    }
    [arr_selectedCells removeObjectsInArray:tempRemovePDFS];
    
    // pdf data
    [self addDataToPDF:arr_selectedCells];
    
    // close & save pdf
    [self finishAndSavePDF];
    
    // get newly saved pdf from documents directory and send
    NSData *pdfData = [self getPDFAsNSDataNamed:@"Demo.pdf"];
    NSMutableArray*attachData = [[NSMutableArray alloc] initWithObjects:pdfData, nil];
    
    // remove anything already added to the created pdf
    // remove cover image
    [arr_selectedCells removeObjectAtIndex:0];
    
    // remove any other images from array
    NSMutableArray *tooDelete = [NSMutableArray array];
    for (id file in arr_selectedCells) {
        if ([[file pathExtension] isEqualToString:@"jpg"]) {
            [tooDelete addObject:file];
            NSLog(@"removed: %@", file);
        }
    }
    
    [arr_selectedCells removeObjectsInArray:tooDelete];
    
    // add BACK in any added pdfs
    [attachData addObjectsFromArray:tempRemovePDFS];
    
    // prepare final array to send to email,
    NSArray *attachmentData;
    [attachData addObjectsFromArray:arr_selectedCells];
    attachmentData = [NSArray arrayWithArray:attachData];
    return attachmentData;
}

-(NSData*)getPDFAsNSDataNamed:(NSString*)name
{
    // find new pdf and add to mydata for emailing
    NSString *searchFilename = name; // name of the PDF you are searching for
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsDirectory];
    NSString *documentsSubpath;
    NSData *myPdfData;
    while (documentsSubpath = [direnum nextObject])
    {
        if (![documentsSubpath.lastPathComponent isEqual:searchFilename]) {
            continue;
        }
        NSLog(@"found %@", documentsSubpath);
        NSString *pdfFileName = [documentsDirectory stringByAppendingPathComponent:searchFilename];
        NSLog(@"t %@", pdfFileName);
        myPdfData = [NSData dataWithContentsOfFile:pdfFileName];
    }
    
    return myPdfData;
}

- (void)setupPDFDocumentNamed:(NSString*)name Width:(float)width Height:(float)height
{
    _pageSize = CGSizeMake(width, height);
    NSString *pdfName = @"Demo.pdf";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pdfFileName = [documentsDirectory stringByAppendingPathComponent:pdfName];
    
    UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectZero, nil);
    
    _pageSize = CGSizeMake(width, height);
    
}

- (void)beginPDFPage {
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, _pageSize.width, _pageSize.height), nil);
}

-(void)addDataToPDF:(NSMutableArray*)data
{
    
    NSString	*justFileName;
    UIImage		*pngImage;
    NSInteger	currentPage = 0;
    
    for (id file in data)
    {
        // Mark the beginning of a new page.
        [self beginPDFPage];
        
        if (currentPage==0) {
            
            justFileName = [[file lastPathComponent] stringByDeletingPathExtension];
            
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:justFileName ofType:@"jpg"];
            
            UIImage *pngImage = [UIImage imageWithContentsOfFile:imagePath];
            [pngImage drawInRect:CGRectMake(0, 0, _pageSize.width, _pageSize.height)];
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGAffineTransform ctm = CGContextGetCTM(context);
            
            // Translate the origin to the bottom left.
            // Notice that 842 is the size of the PDF page.
            CGAffineTransformTranslate(ctm, 0.0, 850);
            
            // Flip the handedness of the coordinate system back to right handed.
            CGAffineTransformScale(ctm, 1.0, -1.0);
            
        } else {
            
            justFileName = [[file lastPathComponent] stringByDeletingPathExtension];
            
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:justFileName ofType:@"jpg"];
            
            pngImage = [UIImage imageWithImage:[UIImage imageWithContentsOfFile:imagePath] scaledToWidth:_pageSize.width];
            [pngImage drawInRect:CGRectMake(0, 0, pngImage.size.width, pngImage.size.height)];
            
        }
        
        NSData *imgData = UIImageJPEGRepresentation(pngImage, 0);
        NSString *string = [NSByteCountFormatter stringFromByteCount:[imgData length] countStyle:NSByteCountFormatterCountStyleFile];
        
        [filesInPDF addObject:[NSNumber numberWithFloat:[string floatValue]]];
        
        currentPage++;
    }
    
    CGFloat i;
    for (int g = 0; g< [filesInPDF count]; g++) {
        i += [filesInPDF[g] floatValue];
    }

    // link added to end pdf
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform ctm = CGContextGetCTM(context);
    
    // Translate the origin to the bottom left.
    // Notice that 850 is the size of the PDF page.
    CGAffineTransformTranslate(ctm, 0.0, 850);
    
    // Flip the handedness of the coordinate system back to right handed.
    CGAffineTransformScale(ctm, 1.0, -1.0);
    
}

- (void)drawPDFPageNumber:(NSInteger)pageNum
{
    NSString *pageString = [NSString stringWithFormat:@"Page %li", (long)pageNum];
    UIFont *theFont = [UIFont systemFontOfSize:12];
    CGSize maxSize = CGSizeMake(612, 72);
    CGRect textRect = [pageString boundingRectWithSize:maxSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:theFont}
                                               context:nil];
    
    CGSize pageStringSize = textRect.size;
    
    CGRect stringRect = CGRectMake(40.0,
                                   790 + ((72.0 - pageStringSize.height) / 2.0),
                                   pageStringSize.width,
                                   pageStringSize.height);
    
    NSDictionary *attributesDict;
    NSMutableAttributedString *attString;
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    
    attributesDict = @{NSForegroundColorAttributeName : [UIColor whiteColor],NSParagraphStyleAttributeName : style};
    attString = [[NSMutableAttributedString alloc] initWithString:pageString attributes:attributesDict];
    
    [attString drawInRect:stringRect];
}

- (void)finishAndSavePDF {
    UIGraphicsEndPDFContext();
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pdfDirectoryString = [NSString stringWithFormat:@"%@/Demo.pdf", documentsDirectory];
    
    NSData *pdfData = [NSData dataWithContentsOfFile:pdfDirectoryString];
    NSError *error = nil;
    if ([pdfData writeToFile:pdfDirectoryString options:NSDataWritingAtomic error:&error]) {
        // file saved
    } else {
        // error writing file
        NSLog(@"Unable to write PDF to %@. Error: %@", pdfDirectoryString,[error localizedDescription]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
