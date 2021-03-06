//
//  YLTViewController.m
//  YLT_Tangram
//
//  Created by xphaijj0305@126.com on 12/19/2018.
//  Copyright (c) 2018 xphaijj0305@126.com. All rights reserved.
//

#import "YLTViewController.h"
#import "YLT_Tangram.h"
#import <YLT_Kit/YLT_Kit.h>
#import <YLT_BaseLib/YLT_BaseLib.h>
#import <AFNetworking/AFNetworking.h>
#import <RegexKitLite/RegexKitLite.h>
#import <YLT_Crypto/YLT_Crypto.h>

@interface TestView : YLT_TangramView

@end

@implementation TestView

- (void)setPageData:(NSDictionary *)pageData {
    [super setPageData:pageData];
    NSLog(@"%@", pageData);
}

@end




@interface YLTViewController ()

@property (nonatomic, strong) YLT_TangramView *tangramView;

@property (nonatomic, strong) id pageData;

@end

@implementation YLTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSString *str = [YLT_TangramUtils valueFromSourceData:@{@"data":@{@"title":@"123456"}, @"source":@"sourceData"} keyPath:@"来自:${data.title}点赞:${source}"];
//    YLT_Log(@"%@", str);
//
//    id data = [YLT_TangramUtils valueFromSourceData:@{@"data":@{@"title":@"123456"}, @"source":@"sourceData"} keyPath:@"${data}"];
//
//    YLT_Log(@"%@", data);
//
//    return;
    
    
    [YLT_TangramManager shareInstance].tangramKey = @"woBLXnIJakCTnqyU";
    uint8_t iv[16] = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08, 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08}; //直接影响加密结果!
    NSData *ivData = [NSData dataWithBytes:iv length:sizeof(iv)];
    [YLT_TangramManager shareInstance].tangramIv = ivData;
    
    [YLT_TangramManager shareInstance].tangramImageURLString = ^NSString *(NSString *path) {
        path = [NSString stringWithFormat:@"https://img2.ultimavip.cn/%@?imageView2/2/w/153/h/153&imageslim", path];
        return path;
    };
    [YLT_TangramManager shareInstance].tangramRequest = ^(NSArray<TangramRequest *> *requests, void (^success)(NSDictionary *result)) {
        //做对应的网络请求
        static AFHTTPSessionManager *sessionManager = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://gw.ultimablack.cn/"]];
            sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json", nil];
        });
        __block NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        dispatch_group_t group = dispatch_group_create();
        [requests enumerateObjectsUsingBlock:^(TangramRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_group_enter(group);
            [sessionManager POST:obj.path parameters:obj.params progress:^(NSProgress * _Nonnull uploadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]] && [((NSDictionary *) responseObject).allKeys containsObject:@"data"]) {
                    [data setObject:responseObject[@"data"] forKey:obj.keyname];
                } else {
                    [data setObject:responseObject forKey:obj.keyname];
                }
                dispatch_group_leave(group);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [data setObject:error forKey:obj.keyname];
                dispatch_group_leave(group);
            }];
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (success) {
                success(data);
            }
        });
    };
    
    [YLT_TangramManager shareInstance].tangramViewFromPageModel = ^UIView *(NSDictionary *data) {
        UIView *view = [[UIView alloc] init];
        return view;
    };
    
    
    
    
    //    UIViewController *target = [self ylt_routerToURL:@"ylt://YLT_TangramVC/tangramWithRequestParams:?path=http://127.0.0.0" isClassMethod:YES arg:nil completion:^(NSError *error, id response) {
    //    }];
    //    [self.navigationController pushViewController:target animated:YES];
    
    NSDictionary *map = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"realPage" ofType:@"geojson"]] options:NSJSONReadingAllowFragments error:nil];
    
    YLT_TangramVC *vc = [YLT_TangramVC tangramWithPages:map];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
