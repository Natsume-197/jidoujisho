import 'dart:io';

import 'package:daijidoujisho/dictionary/dictionary.dart';
import 'package:daijidoujisho/dictionary/dictionary_utils.dart';
import 'package:flutter/material.dart';

import 'package:daijidoujisho/dictionary/dictionary_entry.dart';
import 'package:daijidoujisho/dictionary/dictionary_extract_params.dart';
import 'package:daijidoujisho/dictionary/dictionary_result.dart';
import 'package:daijidoujisho/dictionary/dictionary_search_results.dart';

abstract class DictionaryFormat {
  DictionaryFormat({
    required this.formatName,
    this.formatIcon = Icons.archive,
  });

  /// The name of this dictionary format. For example, this could be a
  /// "Yomichan Term Bank Dictionary" or "ABBYY Lingvo".
  late String formatName;

  /// An appropriate icon for this dictionary format.
  late IconData formatIcon;

  /// Given a [Uri], return whether or not the source is of this dictionary
  /// format.
  bool isUriSupported(Uri uri);

  /// Given a [File], prepare a working [Directory] such that it will be
  /// possible to make relative commands (in the directory) to be able to
  /// get a dictionary's name, its entries and other related metadata that
  /// will be useful for preservation.
  ///
  /// For many formats, this will likely be a ZIP extraction operation. A
  /// given parameter [targetDirectory] is where the final working directory
  /// should be, and where the rest of the operations will be performed.
  ///
  /// See [ImportPreparationParams] for how to work with the individual input
  /// parameters.
  Future<Directory> prepareWorkingDirectory(ImportPreparationParams params);

  /// Given a [Directory] of files pertaining to this dictionary format,
  /// return a [String] that will refer to a dictionary's name in this format.
  ///
  /// If this format does not offer a way for a dictionary's name to be
  /// represented in its schema, return a unique [String] instead such that
  /// collisions with other dictionaries will not be likely.
  ///
  /// See [ImportProcessingParams] for how to work with the individual input
  /// parameters.
  Future<String> getDictionaryName(ImportProcessingParams params);

  /// Given a [Directory] of files pertaining to this dictionary format,
  /// return a list of [DictionaryEntry] that will be added to the database.
  ///
  /// See [ImportProcessingParams] for how to work with the individual input
  /// parameters.
  Future<List<DictionaryEntry>> extractDictionaryEntries(
      ImportProcessingParams params);

  /// Given a [Directory] of files pertaining to this dictionary format,
  /// prepare a [Map] of metadata that will be used for cleaning up and
  /// enhancing raw database results.
  ///
  /// For example, a dictionary format may make use of tags separate from the
  /// entry. This will be preserved by the dictionary. This field may also
  /// be used to store trivial metadata pertaining to the dictionary itself.
  ///
  /// See [ImportProcessingParams] for how to work with the individual input
  /// parameters.
  Future<Map<String, String>> getDictionaryMetadata(
      ImportProcessingParams params);

  /// Process clean results from the searched entries.
  DictionarySearchResult processResultsFromEntries(
      List<DictionaryEntry> entries);
}
