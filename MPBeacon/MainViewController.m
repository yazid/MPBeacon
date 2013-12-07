//
//  MainViewController.m
//  MPBeacon
//
//  Created by Yazid Azahari on 12/2/13.
//  Copyright (c) 2013 Yazid Azahari. All rights reserved.
//

#import "MainViewController.h"
#import "MPBeacon.h"

@interface MainViewController ()

@property (nonatomic, strong) MPBeacon* myBeacon;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@end

@implementation MainViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.myBeacon = [[MPBeacon alloc] initWithUUIDAndIdentifier:@"00000000-0000-0000-0000-000000000000" andServiceIdentifier:@"MPBeacon"];
    self.myBeacon.delegate = self;
    [self.myBeacon start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.myBeacon.connectedBeacons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [[self.myBeacon.connectedBeacons objectAtIndex:indexPath.row] objectForKey:@"deviceName"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %f",[[self.myBeacon.connectedBeacons objectAtIndex:indexPath.row] objectForKey:@"proximityLabel"],((CLBeacon *)[[self.myBeacon.connectedBeacons objectAtIndex:indexPath.row] objectForKey:@"beacon"]).accuracy];
    
    return cell;
}

-(IBAction)jumpstart:(id)sender{
    self.myBeacon.start;
}

-(void)connectedBeaconsDidUpdate
{
    [self.tableView reloadData];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
