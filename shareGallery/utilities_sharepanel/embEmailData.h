//
//  embEmail.h
//  embMailClass
//
//  Created by Evan Buxton on 1/15/14.
//  Copyright (c) 2014 neoscape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface embEmailData : NSObject
{
	NSArray		*to;
	NSArray		*cc;
	NSArray		*bcc;
	NSString	*subject;
	NSString	*body;
	NSArray		*attachment;
}

@property (nonatomic, assign) BOOL optionsAlert;

-(void)setTo:(NSArray*)to;
-(NSArray*)to;

-(void)setCc:(NSArray*)cc;
-(NSArray*)cc;

-(void)setBcc:(NSArray*)bcc;
-(NSArray*)bcc;

-(void)setSubject:(NSString*)subject;
-(NSString*)subject;

-(void)setBody:(NSString*)body;
-(NSString*)body;

-(void)setAttachment:(NSArray*)attachment;
-(NSArray*)attachment;

-(void)setOptionsAlert:(BOOL)options;

@end
