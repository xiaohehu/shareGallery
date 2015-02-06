//
//  embEmail.m
//  embMailClass
//
//  Created by Evan Buxton on 1/15/14.
//  Copyright (c) 2014 neoscape. All rights reserved.
//

#import "embEmailData.h"
#import <MessageUI/MFMailComposeViewController.h>

#define kemailShowNSLogBOOL NO

@implementation embEmailData

- (id)init {
    self = [super init];
    if (self) {
		// Delay execution of my block for 0.1 seconds.
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self postEmail];
		});
    }
    return self;
}

-(void)setTo:(NSArray*)_to
{
	to = _to;
	if (kemailShowNSLogBOOL) NSLog(@"%@",to);
}

-(NSArray*)to {
	return to;
}

-(void)setCc:(NSArray*)_cc
{
	cc = _cc;
	if (kemailShowNSLogBOOL) NSLog(@"%@",cc);
}

-(NSArray*)cc {
	return cc;
}

-(void)setBcc:(NSArray*)_bcc
{
	bcc = _bcc;
	if (kemailShowNSLogBOOL) NSLog(@"%@",bcc);
}

-(NSArray*)bcc {
	return bcc;
}

-(void)setSubject:(NSString*)_subject
{
	subject = _subject;
	if (kemailShowNSLogBOOL) NSLog(@"%@",subject);
}

-(NSString*)subject {
	return subject;
}

-(void)setBody:(NSString*)_body
{
	body = _body;
	if (kemailShowNSLogBOOL) NSLog(@"%@",body);
}

-(NSString*)body {
	return body;
}

-(void)setAttachment:(NSArray*)_attachment
{
	attachment = _attachment;
	if (kemailShowNSLogBOOL) NSLog(@"%@",attachment);
}

-(NSArray*)attachment {
	return attachment;
}

-(void)setOptionsAlert:(BOOL)options
{
    if (options)
    {
		if (kemailShowNSLogBOOL) NSLog(@"options");
    }
    else
    {
		if (kemailShowNSLogBOOL) NSLog(@"no options");
    }
	
    _optionsAlert = options;
}

-(void)postEmail
{
	// http://stackoverflow.com/questions/10836463/when-to-use-nsnotificationcenter
	NSMutableArray *arr_emailData;
	[arr_emailData addObject:self];
	if (kemailShowNSLogBOOL) NSLog(@"post");
	NSDictionary *theInfo = [NSDictionary dictionaryWithObjectsAndKeys:arr_emailData,@"myArray", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"emailData" object:self userInfo:theInfo];
}

@end
