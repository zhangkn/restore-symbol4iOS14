// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2015 Steve Nygard.

#import "RSScanMethodVisitor.h"

#import "CDClassDump.h"
#import "CDObjectiveC1Processor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDLCDylib.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCClassReference.h"
#import "CDOCMethod.h"
#import <mach-o/nlist.h>
#import <mach-o/stab.h>

//#import "CDTypeController.h"

@interface RSScanMethodVisitor ()

@property (nonatomic, strong) CDOCProtocol *context;

@property (nonatomic, weak) RSSymbolCollector * collector;

@end

#pragma mark -

@implementation RSScanMethodVisitor
{
    CDOCProtocol *_context;

}

- (id)initWithSymbolCollector:(RSSymbolCollector *)collector
{
    if ((self = [super init])) {
        _context = nil;
        _collector = collector;
    }

    return self;
}

#pragma mark -

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self setContext:protocol];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    [self setContext:aClass];
    
    // 这里生成类的符号，测试发现对于调用栈恢复，不是必要的

    if (aClass.classAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"_OBJC_CLASS_$_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.classAddress type:(N_SECT | N_EXT)];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:0 type:N_GSYM];
        [self.collector addSymbol:s1];

    }

    if (aClass.classRoAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_CLASS_RO_$_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.classRoAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.classRoAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.metaClassAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"_OBJC_METACLASS_$_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.metaClassAddress type:(N_SECT | N_EXT)];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:0 type:N_GSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.metaClassRoAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_METACLASS_RO_$_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.metaClassRoAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.metaClassRoAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.instanceMethodsAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_$_INSTANCE_METHODS_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.instanceMethodsAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.instanceMethodsAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.protocolsAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_CLASS_PROTOCOLS_$_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.protocolsAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.protocolsAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.instanceIvarAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_$_INSTANCE_VARIABLES_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.instanceIvarAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.instanceIvarAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }

    if (aClass.propertiesAddress != 0) {
        NSString * name = [NSString stringWithFormat:@"__OBJC_$_PROP_LIST_%@", aClass.name];
        RSSymbol *s = [RSSymbol symbolWithName:name address:aClass.propertiesAddress];
        [self.collector addSymbol:s];

        RSSymbol *s1 = [RSSymbol symbolWithName:name address:aClass.propertiesAddress type:N_STSYM];
        [self.collector addSymbol:s1];
    }
    
}


- (void)willVisitCategory:(CDOCCategory *)category;
{
    [self setContext:category];
}


- (NSString *)getCurrentClassName{
    if ([_context isKindOfClass:[CDOCClass class]]) {
        return _context.name;
    } else if([_context isKindOfClass:[CDOCCategory class]]) {
        NSString * className = [[(CDOCCategory *)_context classRef] className];
        if (!className) className = @"";
        return [NSString stringWithFormat:@"%@(%@)", className ,_context.name];
    }
    return _context.name;
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    if (method.address == 0 ) {
        return;
    }
    
    NSString *name = [NSString stringWithFormat:@"+[%@ %@]", [self getCurrentClassName], method.name];
    
    RSSymbol *s = [RSSymbol symbolWithName:name address:method.address];
    
    [self.collector addSymbol:s];
    
    RSSymbol *s1 = [RSSymbol symbolWithName:name address:method.address type:N_FUN];
    [self.collector addSymbol:s1];
    
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    if (method.address == 0 ) {
        return;
    }
    NSString *name = [NSString stringWithFormat:@"-[%@ %@]", [self getCurrentClassName], method.name];
    
    RSSymbol *s = [RSSymbol symbolWithName:name address:method.address];
    
    [self.collector addSymbol:s];
    
    RSSymbol *s1 = [RSSymbol symbolWithName:name address:method.address type:N_FUN];
    [self.collector addSymbol:s1];
}


#pragma mark -

- (void)setContext:(CDOCProtocol *)newContext;
{
    if (newContext != _context) {
        _context = newContext;
    }
}



@end
