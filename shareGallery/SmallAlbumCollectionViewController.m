//
//  SmallAlbumCollectionViewController.m
//  shareGallery
//
//  Created by Xiaohe Hu on 2/10/15.
//  Copyright (c) 2015 Neoscape. All rights reserved.
//

#import "SmallAlbumCollectionViewController.h"
#import "UIImage+ScaleToFit.h"

@interface SmallAlbumCollectionViewController ()
{
    NSMutableArray      *selectedBytes;
    NSNumber            *byt;
    CGFloat             totalBhytes;
    NSMutableArray		*bytesInPDF;
}
@property (nonatomic, strong) NSMutableArray        *arr_selectedItem;
@end

@implementation SmallAlbumCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _arr_selectedItem   = [[NSMutableArray alloc] init];
    selectedBytes       = [[NSMutableArray alloc] init];
    bytesInPDF          = [[NSMutableArray alloc] init];
    
    self.collectionView.allowsMultipleSelection = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 100;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 10.0, 10.0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor greenColor];
    UIView *selectedView = [[UIView alloc] initWithFrame:cell.bounds];
    selectedView.backgroundColor = [UIColor orangeColor];
    cell.selectedBackgroundView = selectedView;
    // Configure the cell
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = @"Lobby View.jpg";
    [_arr_selectedItem addObject:fileName];
    
    //Added image data to the byte array
    byt = [NSNumber numberWithFloat:[self byteSizeOfFile:fileName]];
    [selectedBytes addObject:byt];
    [self updateTotalBytes];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_arr_selectedItem removeLastObject];
}

- (NSArray *)getSelectedItem
{
    NSArray *arrayReturn = [NSArray arrayWithArray:_arr_selectedItem];
    return arrayReturn;
}

- (CGFloat)getSelectedItemSize
{
    return totalBhytes;
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
//    NSLog(@"\n\n %@", bytesInPDF);
    for (NSNumber *t in bytesInPDF) {
        totalBhytes = totalBhytes+[t intValue];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [selectedBytes removeAllObjects];
    selectedBytes = nil;
    [bytesInPDF removeAllObjects];
    bytesInPDF = nil;
    [_arr_selectedItem removeAllObjects];
    _arr_selectedItem = nil;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
