/*--------------------------------------------------*/

#import "ViewController.h"
#import "SBubblesView.h"

/*--------------------------------------------------*/

typedef NS_ENUM(NSUInteger, SBubblesViewType) {
    SBubblesViewTypeAlpha,
    SBubblesViewTypeTransition,
    SBubblesViewTypeImages,
};

/*--------------------------------------------------*/
@interface ViewController () <SBubblesViewDataSource>

@property(nonatomic, weak) IBOutlet SBubblesView *bubblesView;;
@property(nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;;

- (IBAction)reload:(id)sender;

@end

/*--------------------------------------------------*/

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.bubblesView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self _update];
}

#pragma mark - IBActions

- (IBAction)reload:(id)sender {
    [self _update];
}

#pragma mark - SFlowerViewDataSource

- (NSInteger)numberOfBubblesInBubblesView:(SBubblesView *)bubblesView {
    NSInteger count = [self _randomWithMin:6 max:12];
    return count;
}

- (UIImage *)bubblesView:(SBubblesView *)bubblesView imageForIndex:(NSInteger)index {
    if (self.segmentControl.selectedSegmentIndex != SBubblesViewTypeImages) {
        return nil;
    }
    static NSArray *images = nil;
    if(images == nil) {
        images = @[@"vk", @"g+", @"fb", @"tw"];
    }
    NSInteger imageIndex = [self _randomWithMin:0 max:images.count];
    return [UIImage imageNamed:images[imageIndex]];
}

- (NSString*)bubblesView:(SBubblesView *)bubblesView titleForIndex:(NSInteger)index {
    if (self.segmentControl.selectedSegmentIndex == SBubblesViewTypeImages) {
        return nil;
    }
    static NSString *titles = nil;
    if(titles == nil) {
        titles = @"ABCDEFGHFJKLMNOPQRSTUVWXYZ";
    }
    NSRange range = NSMakeRange(MIN(index, titles.length - 1), 1);

    return [titles substringWithRange:range];
}

#pragma mark - Private

- (NSInteger)_randomWithMin:(NSInteger)min max:(NSInteger)max {
    return (arc4random() % (max - min)) + min;
}

- (void)_update {
    switch (self.segmentControl.selectedSegmentIndex) {
        case SBubblesViewTypeAlpha:
            self.bubblesView.intersectCoefficient = 0;
            self.bubblesView.rotating = YES;
            self.bubblesView.appearanceType = SBubblesViewAppearanceTypeAlpha;
            self.bubblesView.animationDuration = 0.25f;
            break;
        case SBubblesViewTypeTransition:
            self.bubblesView.intersectCoefficient = 0.1f;
            self.bubblesView.rotating = NO;
            self.bubblesView.appearanceType = SBubblesViewAppearanceTypeTransition;
            self.bubblesView.animationDuration = 0.15f;
            break;
        case SBubblesViewTypeImages:
            self.bubblesView.bounces = YES;
            self.bubblesView.intersectCoefficient = 0.15f;
            self.bubblesView.appearanceType = SBubblesViewAppearanceTypeTransition;
            self.bubblesView.animationDuration = 0.2f;
            break;

        default:
            break;
    }

    [self.bubblesView reloadData];
    [self.bubblesView startAnimating];
}

@end
