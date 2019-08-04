/*

 Copyright (c) 2019 rokudogobu

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 */

#import <Foundation/Foundation.h>

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

CFPropertyListRef __CopyAppValueForKey( CFStringRef appid, CFStringRef key, CFPropertyListRef def ) {
    CFPropertyListRef val = CFPreferencesCopyAppValue( key, appid );
    if ( ! val ) CFPreferencesSetAppValue( key, def, appid );
    return val ? val : def;
}

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSError * err;
    NSStringEncoding enc;
    NSString * str = [NSString stringWithContentsOfURL:(__bridge NSURL *)url
                                          usedEncoding:&enc
                                                 error:&err];
    if ( str ) {
        CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle( preview );

        CFStringRef appid = CFBundleGetIdentifier( bundle );

        CFStringRef style       = (CFStringRef)__CopyAppValueForKey( appid, CFSTR( "style" ), CFSTR( "solarized-dark" ) );

        NSString * fontSize     = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "font-size"      ), CFSTR( "12px" ));
        NSString * fontFamily   = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "font-family"    ), CFSTR( "" ));
        NSString * lineHeight   = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "line-height"    ), CFSTR( "1.25rem" ));
        NSString * tabSize      = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "tab-size"       ), CFSTR( "4" ));

        NSString * lnFontFamily = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "ln-font-family" ), CFSTR( "Courier New" ));
        NSString * lnFontSize   = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "ln-font-size"   ), CFSTR( "0.9rem" ));
        NSString * lnFontColor  = (__bridge NSString *)__CopyAppValueForKey( appid, CFSTR( "ln-font-color"  ), CFSTR( "#666" ));

        CFPreferencesAppSynchronize( appid );

        NSString * html = [NSString stringWithFormat:
                           @"<!DOCTYPE html>"
                           "<html>"
                             "<head>"
                               "<meta charset=\"UTF-8\" />"
                               "<link rel=\"stylesheet\" type=\"text/css\" href=\"cid:reset.css\" />"
                               "<style type=\"text/css\">"
                                 ":root {"
                                   "font-size: %@;"
                                   "font-family: %@ monospace;"
                                 "}"
                                 "code {"
                                   "line-height: %@;"
                                   "tab-size: %@;"
                                 "}"
                                 ".hljs-ln-n {"
                                   "font-size: %@;"
                                   "min-width: 2rem;"
                                   "color: %@;"
                                   "font-family: \"%@\", monospace;"
                                   "text-align: end;"
                                   "margin: 0 1.25rem 0 0.5rem;"
                                 "}"
                               "</style>"
                               "<link rel=\"stylesheet\" type=\"text/css\" href=\"cid:color.css\" />"
                               "<script src=\"cid:highlight.js\"></script>"
                               "<script src=\"cid:highlightjs-line-numbers.js\"></script>"
                               "<script>"
                                 "document.addEventListener('DOMContentLoaded', (event) => {"
                                   "document.querySelectorAll('pre code').forEach((block) => {"
                                     "hljs.highlightBlock(block);"
                                   "});"
                                   "document.body.style.backgroundColor = window.getComputedStyle( document.querySelector('#colorpicker .hljs'), null ).getPropertyValue('background-color');"
                                   "document.querySelectorAll('code.hljs').forEach((block) => {"
                                     "hljs.lineNumbersBlock(block);"
                                   "});"
                                 "});"
                               "</script>"
                             "</head>"
                             "<body>"
                               "<pre><code>"
                                 "%@"
                               "</code></pre>"
                               "<div id=\"colorpicker\" style=\"width:0;height:0;display:hidden;\"><span class=\"hljs\"></span></div>"
                             "</body>"
                           "</html>",
                           fontSize,
                           fontFamily.length ? [NSString stringWithFormat:@"\"%@\",", fontFamily]: @"",
                           lineHeight,
                           tabSize,
                           lnFontFamily,
                           lnFontSize,
                           lnFontColor,
                           (__bridge NSString *)CFXMLCreateStringByEscapingEntities( kCFAllocatorDefault, (__bridge CFStringRef)str, NULL ) ];

        NSURL * hlURL = (__bridge NSURL *)CFBundleCopyResourceURL( bundle, CFSTR( "highlight.pack.js" ), NULL, NULL );
        NSData * hlData = [NSData dataWithContentsOfURL:hlURL];

        NSURL * hllnURL = (__bridge NSURL *)CFBundleCopyResourceURL( bundle, CFSTR( "highlightjs-line-numbers.min.js" ), NULL, NULL );
        NSData * hllnData = [NSData dataWithContentsOfURL:hllnURL];

        NSURL * cssURL = (__bridge NSURL *)CFBundleCopyResourceURL( bundle, style, CFSTR( "css" ), CFSTR( "styles" ) );
        NSData * cssData = [NSData dataWithContentsOfURL:cssURL];

        NSURL * resetURL = (__bridge NSURL *)CFBundleCopyResourceURL( bundle, CFSTR( "reset.css" ), NULL, NULL );
        NSData * resetData = [NSData dataWithContentsOfURL:resetURL];

        NSDictionary *properties = @{
            (__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
            (__bridge NSString *)kQLPreviewPropertyMIMETypeKey : @"text/html",
            (__bridge NSString *)kQLPreviewPropertyAttachmentsKey: @{
                @"reset.css": @{
                    (__bridge NSString *)kQLPreviewPropertyMIMETypeKey:@"text/css",
                    (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey:resetData
                },
                @"color.css": @{
                    (__bridge NSString *)kQLPreviewPropertyMIMETypeKey:@"text/css",
                    (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey:cssData
                },
                @"highlight.js" : @{
                    (__bridge NSString *)kQLPreviewPropertyMIMETypeKey:@"text/javascript",
                    (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey:hlData
                },
                @"highlightjs-line-numbers.js":@{
                    (__bridge NSString *)kQLPreviewPropertyMIMETypeKey:@"text/javascript",
                    (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey:hllnData
                }
            }
        };

        QLPreviewRequestSetDataRepresentation( preview,
                                              (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                              kUTTypeHTML,
                                              (__bridge CFDictionaryRef)properties );

        CFRelease( style );
    }
    return kQLReturnNoError;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
