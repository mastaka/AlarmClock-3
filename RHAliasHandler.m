#import "RHAliasHandler.h"


@implementation RHAliasHandler

/**
Detects whether the file at the given path is an alias.
**/
+ (BOOL)isAliasFile:(NSString *)path
{
    BOOL isAlias = NO;
	
    NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:path error:nil];

    if(uti && [[NSWorkspace sharedWorkspace] type:uti conformsToType:(id)kUTTypeAliasFile])
    {
        isAlias = YES;
    }

    return isAlias;
}

/**
 Converts an alias path to the actual path of the file.
 
 Aliases are special files which store a pointer to an iNode.
 Thus, aliases always work, even when the original file is moved.
 Aliases are the default shortcut mechanism created by the Finder.
**/
+ (NSString *)resolveAlias:(NSString *)path
{
    NSString *resolvedPath = nil;
	
    NSURL *url = [NSURL fileURLWithPath:path];
	
	NSData* bookmarkData = [NSURL bookmarkDataWithContentsOfURL:url
														  error:nil];
    if (bookmarkData)
	{
		BOOL isStale = NO;
		NSURLBookmarkResolutionOptions options = (NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting);

        NSURL* resolvedURL = [NSURL URLByResolvingBookmarkData:bookmarkData
													   options:options
												 relativeToURL:nil
										   bookmarkDataIsStale:&isStale
														 error:nil];
    if (resolvedURL)
		{
			resolvedPath = url.absoluteString;
		}
	}
	
	return resolvedPath;
}

/**
 This method resolves an entire path, resolving any aliases within the path.
 
 This was added after I received bug reports from users who moved their Music folder,
 and left an alias in the original location. Thus the path to the XML file was still
 "~/Music/iTunes/iTunes Music Library.xml", but the Music folder was an alias.
**/
+ (NSString *)resolvePath:(NSString *)path
{
	// Create a mutable string to incrementally store the resolved path in
    NSMutableString *resolvedPath = [NSMutableString stringWithCapacity:[path length]];
    
	// Extract all the components along the path
	// This includes all enclosing directories, and the final file
    NSArray *components = [path pathComponents];
	
	// Note: We are starting from 1 to ignore the first path component which is always "/"
	int i;
	BOOL failed = NO;
	for(i = 1; i < [components count] && !failed; i++)
	{
		// Get the path up to the current point
		// This includes everything we've resolved so far, and the current path component
        NSString *currentPath = [resolvedPath stringByAppendingPathComponent:[components objectAtIndex:i]];
		
        if([self isAliasFile:currentPath])
		{
            NSString *resolvedAliasPath = [self resolveAlias:currentPath];
			
			// resolvedAliasPath is nil if we were unable to resolve the alias
			// This would happen if the alias was bad. As in the original was deleted.
			if(resolvedAliasPath != nil)
			{
				// Replace entire string with resolved path from alias
				NSRange fullRange = NSMakeRange(0, [resolvedPath length]);
				[resolvedPath replaceCharactersInRange:fullRange withString:resolvedAliasPath];
			}
			else
			{
				failed = YES;
			}
		}
        else
		{
			[resolvedPath appendFormat:@"/%@", [components objectAtIndex:i]];
        }
		
		//NSLog(@"resolvedPath: %@", resolvedPath);
    }
	
	if(failed)
		return nil;
	else
		return resolvedPath;
}

@end
