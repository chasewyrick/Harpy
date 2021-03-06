//
//  ViewController.m
//  Harpy
//
//  Created by midnightchips on 1/4/19.
//  Copyright © 2019 midnightchips. All rights reserved.
//

#import "ViewController.h"

#define CSAppAlertLog(format, ...) { UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ;", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:format, ##__VA_ARGS__] preferredStyle:UIAlertControllerStyleAlert]; [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]]; [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];}


@interface ViewController ()
@property UIRefreshControl *refreshControl;
@property UIBarButtonItem *editButton;
@property UIBarButtonItem *doneButton;
@property UIBarButtonItem *infoButton;
@property UILabel *messageLabel;
@property NSMutableArray *selectedIPs;
@end

//TODO to block internet, do arpspoof -i [interfaceName] -t [target] [gateway](I need to figure out if this can be anything, or must be the box).


@implementation ViewController 
{
    NSMutableArray<NSString *> *tableData;
    NSMutableArray<NSString*> *fullInfo;
    NSMutableArray<NSString*> *ipAdress;
    NSMutableArray<NSString*> *macAddress;
    NSMutableArray<NSString*> *manName;
    NSMutableArray<NSString*> *hostName;
    NSArray<NSString *> *split;
    NSString *output;
}

static BOOL pfBOOL = NO;


- (void)viewDidLoad {
    [super viewDidLoad];
    //Enable Multiple Selection when "Editing"
    [self setToolbarItems:@[
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd actionHandler:^{
        [self kickSelectedIPs:[self.tableView indexPathsForSelectedRows]];
        
    }]
                            
                            ]];
    
    self.navigationController.toolbar.barTintColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];
    self.navigationController.toolbar.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];
    self.navigationController.toolbar.translucent = NO;
    self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0.00 green:0.48 blue:0.52 alpha:1.0];
    //Edit Button
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit actionHandler:^{
        [self.tableView setEditing:YES animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.doneButton, self.infoButton] animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }];
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone actionHandler:^{
        [self.tableView setEditing:NO animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButton, self.infoButton] animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }];
    
    self.infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain actionHandler:^{
        [self presentCredits];
    }];
    self.navigationItem.rightBarButtonItems = @[self.editButton, self.infoButton];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.00 green:0.48 blue:0.52 alpha:1.0];
    
    
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    //Reload View
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor blackColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshDevices)
                  forControlEvents:UIControlEventValueChanged];
    NSString *title = [NSString stringWithFormat:@"Checking for Devices..."];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                forKey:NSForegroundColorAttributeName];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
    self.refreshControl.attributedTitle = attributedTitle;
    
    if (@available(iOS 10.0, *)) {
        self.tableView.refreshControl = self.refreshControl;
    } else {
        [self.tableView addSubview:self.refreshControl];
    }
    //Device Arrays
    ipAdress = [NSMutableArray new];
    macAddress = [NSMutableArray new];
    manName = [NSMutableArray new];
    hostName = [NSMutableArray new];
    self.selectedIPs = [NSMutableArray new];
    self.view.backgroundColor = [UIColor blackColor];
}

-(void)viewDidAppear:(BOOL)animated{
    if(!tableData.count){
        self.navigationItem.title = @"Getting Devices";
        [self refreshDevices];
    }
}


- (NSArray<NSString *> *)createArrays:(NSArray *)fullString{
    //[fullString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
    [ipAdress removeAllObjects];
    [macAddress removeAllObjects];
    [manName removeAllObjects];
    for(NSString *line in fullString){
        NSArray *components = [NSArray new];
        components = [line componentsSeparatedByString:@"\t"];
        if (components.count >= 3) {
            [self->ipAdress addObject:components[0]];
            [self->macAddress addObject:components[1]];
            [self->manName addObject:components[2]];
        }
        //[self->ipAdress addObject:[NSString stringWithFormat: @"%ld", (long)components.count]];
        
    }
    return ipAdress;
}

- (void)refreshDevices{
    self.tableView.backgroundColor = [UIColor blackColor];
    [fullInfo removeAllObjects];
    [tableData removeAllObjects];
    
    fullInfo = [[[self getFullOutput] componentsSeparatedByString:@"\n"]mutableCopy];
    tableData = [[self createArrays:fullInfo]mutableCopy];
    hostName = [self getHostNames:ipAdress];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
        if(!self->tableData.count){
            [self displayNoDevicesAlert];
        }else{
            [self.messageLabel removeFromSuperview];
        }
    
}

- (void)displayNoDevicesAlert{
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
    self.messageLabel.text = @"No devices connected. \n Please enable Wifi/Hotspot and pull to refresh.";
    self.messageLabel.textColor = [UIColor whiteColor];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.font = [UIFont systemFontOfSize:20];
    [self.messageLabel sizeToFit];
    
    self.tableView.backgroundView = self.messageLabel;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.title =  @"Harpy: Unavailable";
}

- (NSString *)getFullOutput{
    NSString *availableInterfaces = [Commands runCommandWithOutput:@"/bin/bash" withArguments:@[@"-c", @"/sbin/ifconfig | grep bridge100"] errors:NO];
    NSString *command = [NSString stringWithFormat:@"/Applications/arpGUI.app/rootIfy /Applications/arpGUI.app/arp-scan -interface %@ --localnet --iabfile=/Applications/arpGUI.app/ieee-iab.txt --ouifile=/Applications/arpGUI.app/ieee-oui.txt  | grep -i '[0-9A-F]\\{2\\}\\(:[0-9A-F]\\{2\\}\\)\\{5\\}' | sort -V", [availableInterfaces length] > 0 ? @"bridge100" : @"en0"];
    if([availableInterfaces length] > 0){
        pfBOOL = YES;
    }
    self.navigationItem.title =  [NSString stringWithFormat:@"Harpy: %@", [availableInterfaces length] > 0 ? @"HotSpot" : @"Wifi" ];
    
    return resultsForCommand(command);//(@"/Applications/arpGUI.app/rootIfy /usr/local/bin/arp-scan -interface en0 --localnet | grep  '[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}' | sort -V");
}



- (NSMutableArray<NSString *> *)getHostNames:(NSArray *)sourceArray{
    NSMutableArray *returnArray = [NSMutableArray new];
    for(NSString *ip in sourceArray){
        NSString *command = [NSString stringWithFormat:@"arp %@", ip];
        NSString *commandOutput = resultsForCommand(command);
        NSArray *components = [NSArray new];
        components = [commandOutput componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (components.count){
            [returnArray addObject:components[0]];
        }
    }
    return returnArray;
}


- (void)kickSelectedIPs:(NSArray *)cellLocations{
    [self.tableView setEditing:NO animated:YES];
    [self.navigationItem setRightBarButtonItem:self.editButton animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
    for (NSIndexPath *indexPath in cellLocations){
        [self.selectedIPs addObject:tableData[indexPath.row]];
        if(pfBOOL){
            [Commands blockIPonPF:tableData[indexPath.row]];
        }else{
            [Commands runCommandOnIP:tableData[indexPath.row]];
        }
        //
    }
    //[MCDataProvider addTasks:self.selectedIPs];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    tableView.backgroundColor = [UIColor blackColor];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [hostName objectAtIndex:indexPath.row];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.00 green:0.48 blue:0.52 alpha:0.25];//[UIColor colorWithRed:0.00 green:0.65 blue:0.58 alpha:0.25]; //[UIColor redColor];
    [cell setSelectedBackgroundView:bgColorView];
    return cell;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{ //[fullInfo objectAtIndex:indexPath.row]
    if (tableView.isEditing) return;
    
    NSString *deviceInfo = [NSString stringWithFormat:@"%@ \n %@", [macAddress objectAtIndex:indexPath.row], [manName objectAtIndex:indexPath.row]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[tableData objectAtIndex:indexPath.row] message:deviceInfo preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *attackAction = [UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        if(pfBOOL){
            [Commands blockIPonPF:[self->ipAdress objectAtIndex:indexPath.row]];
        }else{
            [Commands runCommandOnIP:[self->ipAdress objectAtIndex:indexPath.row]];
        }
    }];
    [alert addAction:okAction];
    [alert addAction:attackAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)presentCredits{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Credits"
                                                                   message:@"Created by: MidnightChips\n Special thanks to:\n CreatureSurvive and Apollo Justice.\n Source and License Available on https://github.com/midnightchip/Harpy"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    UIAlertAction* goAction = [UIAlertAction actionWithTitle:@"Go" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              UIApplication *application = [UIApplication sharedApplication];
                                                              NSURL *URL = [NSURL URLWithString:@"https://github.com/midnightchip/Harpy/blob/master/LICENSE"];
                                                              if (@available(iOS 10.0, *)) {
                                                                  [application openURL:URL options:@{} completionHandler:nil];
                                                              } else {
                                                                  [application openURL:URL];
                                                              }
                                                          }];
    
    [alert addAction:defaultAction];
    [alert addAction:goAction];
    [self presentViewController:alert animated:YES completion:nil];
}


//Copy and paste the IP
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    if (action == @selector(copy:)){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [[UIPasteboard generalPasteboard] setString:cell.textLabel.text];
    }
}

/*- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    <#code#>
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    <#code#>
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    <#code#>
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    <#code#>
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    <#code#>
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    <#code#>
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    <#code#>
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    <#code#>
}

- (void)setNeedsFocusUpdate {
    <#code#>
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    <#code#>
}

- (void)updateFocusIfNeeded {
    <#code#>
}
*/
@end
