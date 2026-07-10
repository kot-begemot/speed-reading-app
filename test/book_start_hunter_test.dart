import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/utils/book_start_hunter.dart';
import 'package:speed_reading_app/utils/word_tokenizer.dart';

void main() {
  test('returns 0 for empty text', () {
    final tokenized = WordTokenizer.tokenize('');
    expect(BookStartHunter.findContentStartIndex(tokenized), 0);
  });

  test('skips Project Gutenberg start marker and header text', () {
    final rawText = '''
Project Gutenberg's eBook of Alice in Wonderland.
This eBook is for the use of anyone anywhere.
*** START OF THE PROJECT GUTENBERG EBOOK ALICE ***

ALICE IN WONDERLAND

CHAPTER I. Down the Rabbit-Hole

Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do.
    ''';
    final tokenized = WordTokenizer.tokenize(rawText);
    final startIndex = BookStartHunter.findContentStartIndex(tokenized);
    
    // The start should point to "Alice was beginning to get very tired..."
    final startWord = tokenized.words[startIndex];
    expect(startWord, 'Alice');
  });

  test('skips copyright and publisher metadata paragraphs', () {
    final rawText = '''
The Great Gatsby
by F. Scott Fitzgerald

Copyright © 1925 by Charles Scribner's Sons.
All rights reserved. No part of this book may be used or reproduced in any manner whatsoever.
ISBN: 978-0-7432-7356-5
Published by Charles Scribner's Sons, New York.

In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since.
    ''';
    final tokenized = WordTokenizer.tokenize(rawText);
    final startIndex = BookStartHunter.findContentStartIndex(tokenized);
    
    final startWord = tokenized.words[startIndex];
    expect(startWord, 'In');
  });

  test('does not skip too much if the text is short (safety fallback)', () {
    final rawText = '''
Copyright © 2026.
All rights reserved.

The end.
    ''';
    final tokenized = WordTokenizer.tokenize(rawText);
    final startIndex = BookStartHunter.findContentStartIndex(tokenized);
    
    // With 15% safety limit, since the book is very short (under 1000 words, clamp is at 1000), 
    // it will scan through all paragraphs, but if it doesn't find a paragraph >= 10 words, 
    // it falls back to 0. Let's make sure it doesn't return an index out of bounds.
    expect(startIndex, 0);
  });

  test('skips table of contents lines', () {
    final rawText = '''
Title of the book
Author Name

CONTENTS

Chapter 1: The Start .............. 5
Chapter 2: The Middle ............. 15
Chapter 3: The End ................ 25

Introduction

This book is about how to read faster and improve comprehension.
    ''';
    final tokenized = WordTokenizer.tokenize(rawText);
    final startIndex = BookStartHunter.findContentStartIndex(tokenized);
    
    final startWord = tokenized.words[startIndex];
    expect(startWord, 'This');
  });
}
