//
//  ViewController.m
//  ARHouse
//
//  Created by lawn.cao on 02/10/2017.
//  Copyright © 2017 lawn. All rights reserved.
//

#import "HomeViewController.h"
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import "Plane.h"


@interface HomeViewController ()<ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) UIView *rightContainerView;
@property (nonatomic, strong) UIButton *button0;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UIButton *button3;
@property (nonatomic, strong) UIButton *button4;
@property (nonatomic, strong) UIButton *button5;
@property (nonatomic, copy  ) NSString *sceneName;

@property (nonatomic, strong) ARSCNView *arSCNView;
@property (nonatomic, strong) ARSession *arSession;
@property (nonatomic, strong) ARWorldTrackingConfiguration *arConfiguration;

@property (nonatomic, strong) NSMutableSet *nodes;
@property (nonatomic, strong) SCNNode *planeNode;
@property (nonatomic, retain) NSMutableDictionary<NSUUID *, Plane *> *planes;

@property (nonatomic, assign) BOOL isOperating;
@property (nonatomic, strong) SCNNode *operatingNode;

@end



@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.arSCNView];
    [self.view addSubview:self.rightContainerView];

    [self.rightContainerView addSubview:self.button0];
    [self.rightContainerView addSubview:self.button1];
    [self.rightContainerView addSubview:self.button2];
    [self.rightContainerView addSubview:self.button3];
    [self.rightContainerView addSubview:self.button4];
    [self.rightContainerView addSubview:self.button5];

    [self setupRecognizers];
    
    _isOperating = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.arSCNView.frame = self.view.bounds;
    
    CGFloat width = 150.0f;
    CGFloat height = self.view.bounds.size.height;
    CGFloat x = self.view.bounds.size.width - width;
    CGFloat y = 0.0f;
    self.rightContainerView.frame = CGRectMake(x, y, width, height);

    CGFloat buttonWidth = 100.0f;
    CGFloat buttonHeight = 40.0f;
    CGFloat buttonX = (width - buttonWidth)/2.0f;
    CGFloat buttonPadding = 20.0f;
    self.button0.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*0, buttonWidth, buttonHeight);
    self.button1.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*1, buttonWidth, buttonHeight);
    self.button2.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*2, buttonWidth, buttonHeight);
    self.button3.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*3, buttonWidth, buttonHeight);
    self.button4.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*4, buttonWidth, buttonHeight);
    self.button5.frame = CGRectMake(buttonX, buttonPadding+(buttonPadding+buttonHeight)*5, buttonWidth, buttonHeight);
    [self.arSession runWithConfiguration:self.arConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.arSession pause];
}

- (void)addAction:(UIButton *)button
{
    _button1.selected = NO;
    _button2.selected = NO;
    _button3.selected = NO;
    _button4.selected = NO;
    button.selected = YES;
    
    if (button == _button1)
    {
        _sceneName = @"Models.scnassets/lamp/lamp.scn";
    }else if (button == _button2)
    {
        _sceneName = @"Models.scnassets/cup/cup.scn";
    }else if (button == _button3)
    {
        _sceneName = @"Models.scnassets/chair/chair.scn";
    }else
    {
        _sceneName = @"Models.scnassets/candle/candle.scn";
    }
}

#pragma mark - Private Methods

// 增加手势
- (void)setupRecognizers
{
    // 添加点
    UITapGestureRecognizer *tapReco = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addNodeFrom:)];
    tapReco.numberOfTapsRequired = 1;
    [self.arSCNView addGestureRecognizer:tapReco];
    
    // 移动
    UIPanGestureRecognizer *panReco = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveNodeFrom:)];
    [self.arSCNView addGestureRecognizer:panReco];
    
    // 缩放
    UIPinchGestureRecognizer *pinchReco = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomNodeFrom:)];
    [self.arSCNView addGestureRecognizer:pinchReco];
    
    // 移除
    UILongPressGestureRecognizer *longReco = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(removeNodeFrom:)];
    longReco.minimumPressDuration = 1.0;
    [self.arSCNView addGestureRecognizer:longReco];

}

- (void)addNodeFrom:(UITapGestureRecognizer *)recognizer
{
    if (!_sceneName || _sceneName.length == 0) {
        [self showMessage:@"请选择家具之后再添加到目标区域"];
        return;
    }
    
    CGPoint tapPoint = [recognizer locationInView:self.arSCNView];
    NSArray<ARHitTestResult *> *result = [self.arSCNView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    if (result.count == 0) {
        return;
    }

    ARHitTestResult *hitResult = [result firstObject];

    SCNVector3 position = SCNVector3Make(
                                         hitResult.worldTransform.columns[3].x,
                                         hitResult.worldTransform.columns[3].y,
                                         hitResult.worldTransform.columns[3].z
                                         );

    SCNScene *scene = [SCNScene sceneNamed:_sceneName];
    if (scene) {
        SCNNode *node = scene.rootNode.childNodes[0];
        [self.nodes addObject:node];
        [self.arSCNView.scene.rootNode addChildNode:node];
        node.position = position;
    }
}

- (void)moveNodeFrom:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.arSCNView];
    NSArray<ARHitTestResult *> *results = [self.arSCNView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    if (results.count == 0) {
        return;
    }
    
    if (!self.isOperating) {
        NSArray<SCNHitTestResult *> *scnResults = [self.arSCNView hitTest:point options:@{}];
        if (scnResults.count == 0) {
            return;
        }
        self.isOperating = YES;
        SCNHitTestResult *scnResult = [scnResults firstObject];
        self.operatingNode = scnResult.node;
    }

    ARHitTestResult *result = [results firstObject];
    SCNVector3 position = SCNVector3Make(
                                         result.worldTransform.columns[3].x,
                                         result.worldTransform.columns[3].y,
                                         result.worldTransform.columns[3].z
                                         );
    if (self.operatingNode) {
        SCNNode *rootNode = [self enumerateNode:self.operatingNode];
        if (rootNode) {
            rootNode.position = position;
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.isOperating = NO;
        self.operatingNode = nil;
    }
}

- (void)zoomNodeFrom:(UIPinchGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.arSCNView];
    NSArray<ARHitTestResult *> *result = [self.arSCNView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    if (result.count == 0) {
        return;
    }
    
    if (!self.isOperating) {
        NSArray<SCNHitTestResult *> *scnResult = [self.arSCNView hitTest:point options:@{}];
        if (scnResult.count == 0) {
            return;
        }
        self.isOperating = YES;
        SCNHitTestResult *scnHitResult = [scnResult firstObject];
        self.operatingNode = scnHitResult.node;
    }

    SCNVector3 scale = SCNVector3Make(recognizer.scale, recognizer.scale, recognizer.scale);

    if (self.operatingNode) {
        SCNNode *rootNode = [self enumerateNode:self.operatingNode];
        if (rootNode) {
            rootNode.scale = scale;
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.isOperating = NO;
        self.operatingNode = nil;
    }
}

- (void)removeNodeFrom:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.arSCNView];
    NSArray<ARHitTestResult *> *result = [self.arSCNView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    if (result.count == 0) {
        return;
    }
    
    if (!self.isOperating) {
        NSArray<SCNHitTestResult *> *scnResult = [self.arSCNView hitTest:point options:@{}];
        if (scnResult.count == 0) {
            return;
        }
        self.isOperating = YES;
        SCNHitTestResult *scnHitResult = [scnResult firstObject];
        self.operatingNode = scnHitResult.node;
    }
    
    if (self.operatingNode) {
        SCNNode *rootNode = [self enumerateNode:self.operatingNode];
        if (rootNode) {
            [rootNode removeFromParentNode];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.isOperating = NO;
        self.operatingNode = nil;
    }
}

- (SCNNode *)enumerateNode:(SCNNode *)node
{
    if ([self.nodes containsObject:node]) {
        return node;
    }
    if (!node.parentNode) {
        return node;
    }
    for (SCNNode *childNode in node.parentNode.childNodes) {
        if ([self.nodes containsObject:childNode]) {
            return childNode;
        }
    }
    return [self enumerateNode:node.parentNode];
}

- (void)hidePlanes
{
    for(NSUUID *planeId in self.planes) {
        [self.planes[planeId] hide];
    }
}

- (void)help
{
    NSMutableString *content = [[NSMutableString alloc] init];
    [content appendString:@"1、首先需要在摄像头对准光线较好的目标区域，最好不要有明显的反射光。\n"];
    [content appendString:@"2、相机会自动聚焦，并且会在地面上画出辅助线。\n"];
    [content appendString:@"3、选中一件家具，在辅助线平面上点击目标区域，家具就会被添加到点击区域。\n"];
    [content appendString:@"4、目前家具可以移动、缩放，后期再加上旋转。\n"];
    [content appendString:@"5、长按一件家具，则可以删除该家具。\n"];
    [self showMessage:content];
}


- (void)showMessage:(NSString *)message
{
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:alertAction];
    [self presentViewController:alert animated:YES completion:NULL];
}


#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    }
    
    Plane *plane = [[Plane alloc] initWithAnchor:(ARPlaneAnchor *)anchor isHidden:NO withMaterial:[Plane currentMaterial]];
    [self.planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
    
//    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
//    SCNBox *plane = [SCNBox boxWithWidth:planeAnchor.extent.x height:0 length:planeAnchor.extent.x chamferRadius:0];
//    plane.firstMaterial.diffuse.contents = [UIColor greenColor];
//    self.planeNode = [SCNNode nodeWithGeometry:plane];
//    self.planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
//    [node addChildNode:self.planeNode];
//    NSLog(@"didAddNode:%p, %p", node, self.planeNode);
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    if (plane == nil) {
        return;
    }
    [plane update:(ARPlaneAnchor *)anchor];
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    [self.planes removeObjectForKey:anchor.identifier];
}


#pragma mark - ARSessionDelegate

- (void)sessionInterruptionEnded:(ARSession *)session
{
    [self refresh];
}

- (void)refresh
{
//    if (self.planeNode) {
//        [self.planeNode removeFromParentNode];
//    }
    
    for(NSUUID *planeId in self.planes) {
        [self.planes[planeId] removeFromParentNode];
    }
    
    for (SCNNode *node in self.nodes) {
        [node removeFromParentNode];
    }
    
    [self.arSession runWithConfiguration:self.arConfiguration options:ARSessionRunOptionResetTracking | ARSessionRunOptionRemoveExistingAnchors];
}

#pragma mark - Getter Methods

- (ARSCNView *)arSCNView
{
    if (_arSCNView == nil) {
        _arSCNView = [[ARSCNView alloc] init];
        _arSCNView.session = self.arSession;
        _arSCNView.automaticallyUpdatesLighting = YES;
        _arSCNView.delegate = self;
        _arSCNView.showsStatistics = YES;
        _arSCNView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    }
    return _arSCNView;
}

- (ARSession *)arSession
{
    if (_arSession == nil) {
        _arSession = [[ARSession alloc] init];
        _arSession.delegate = self;
    }
    return _arSession;
}

- (ARWorldTrackingConfiguration *)arConfiguration
{
    if (_arConfiguration == nil) {
        _arConfiguration = [[ARWorldTrackingConfiguration alloc] init];
        _arConfiguration.planeDetection = ARPlaneDetectionHorizontal;
        _arConfiguration.lightEstimationEnabled = YES;
    }
    return _arConfiguration;
}

- (NSMutableSet *)nodes
{
    if (_nodes == nil) {
        _nodes = [[NSMutableSet alloc] init];
    }
    return _nodes;
}

- (NSMutableDictionary *)planes
{
    if (_planes == nil) {
        _planes = [[NSMutableDictionary alloc] init];
    }
    return _planes;
}

- (UIView *)rightContainerView
{
    if (_rightContainerView == nil) {
        _rightContainerView = [[UIView alloc] init];
        _rightContainerView.backgroundColor = [UIColor clearColor];
        _rightContainerView.layer.borderColor = [UIColor whiteColor].CGColor;
        _rightContainerView.layer.borderWidth = 1.0f;
    }
    return _rightContainerView;
}

- (UIButton *)button0
{
    if (_button0 == nil) {
        _button0 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button0 setTitle:@"操作说明" forState:UIControlStateNormal];
        [_button0 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button0 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button0.backgroundColor = [UIColor clearColor];
        _button0.layer.borderWidth = 1.0f;
        _button0.layer.borderColor = [UIColor whiteColor].CGColor;
        _button0.layer.cornerRadius = 4.0f;
        _button0.clipsToBounds = YES;
        [_button0 addTarget:self action:@selector(help) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button0;
}

- (UIButton *)button1
{
    if (_button1 == nil) {
        _button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button1 setTitle:@"添加台灯" forState:UIControlStateNormal];
        [_button1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button1 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button1.backgroundColor = [UIColor clearColor];
        _button1.layer.borderWidth = 1.0f;
        _button1.layer.borderColor = [UIColor whiteColor].CGColor;
        _button1.layer.cornerRadius = 4.0f;
        _button1.clipsToBounds = YES;
        [_button1 addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button1;
}

- (UIButton *)button2
{
    if (_button2 == nil) {
        _button2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button2 setTitle:@"添加茶杯" forState:UIControlStateNormal];
        [_button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button2 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button2.backgroundColor = [UIColor clearColor];
        _button2.layer.borderWidth = 1.0f;
        _button2.layer.borderColor = [UIColor whiteColor].CGColor;
        _button2.layer.cornerRadius = 4.0f;
        _button2.clipsToBounds = YES;
        [_button2 addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button2;
}

- (UIButton *)button3
{
    if (_button3 == nil) {
        _button3 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button3 setTitle:@"添加椅子" forState:UIControlStateNormal];
        [_button3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button3 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button3.backgroundColor = [UIColor clearColor];
        _button3.layer.borderWidth = 1.0f;
        _button3.layer.borderColor = [UIColor whiteColor].CGColor;
        _button3.layer.cornerRadius = 4.0f;
        _button3.clipsToBounds = YES;
        [_button3 addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button3;
}

- (UIButton *)button4
{
    if (_button4 == nil) {
        _button4 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button4 setTitle:@"添加蜡烛" forState:UIControlStateNormal];
        [_button4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button4 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button4.backgroundColor = [UIColor clearColor];
        _button4.layer.borderWidth = 1.0f;
        _button4.layer.borderColor = [UIColor whiteColor].CGColor;
        _button4.layer.cornerRadius = 4.0f;
        _button4.clipsToBounds = YES;
        [_button4 addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button4;
}

- (UIButton *)button5
{
    if (_button5 == nil) {
        _button5 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button5 setTitle:@"隐藏辅助线" forState:UIControlStateNormal];
        [_button5 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button5 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _button5.backgroundColor = [UIColor clearColor];
        _button5.layer.borderWidth = 1.0f;
        _button5.layer.borderColor = [UIColor whiteColor].CGColor;
        _button5.layer.cornerRadius = 4.0f;
        _button5.clipsToBounds = YES;
        [_button5 addTarget:self action:@selector(hidePlanes) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button5;
}



@end
