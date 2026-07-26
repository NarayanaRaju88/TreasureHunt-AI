import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

/// Wraps Firebase Storage for profile images, treasure images and discovery
/// photos. All errors are translated to the app's [AppException] surface.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a profile image for [uid] and returns its download URL.
  Future<String> uploadProfileImage(String uid, File file) async {
    final ext = _extensionOf(file.path);
    final path = '${AppConstants.storageAvatars}/$uid$ext';
    return _uploadFile(path, file, contentType: _contentTypeFor(ext));
  }

  /// Uploads raw bytes as a profile image (useful for web / picked bytes).
  Future<String> uploadProfileImageBytes(
    String uid,
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    final path = '${AppConstants.storageAvatars}/$uid$extension';
    return _uploadData(path, bytes, contentType: _contentTypeFor(extension));
  }

  /// Uploads a photo captured at a discovery site.
  Future<String> uploadDiscoveryPhoto(
    String uid,
    String discoveryId,
    File file,
  ) async {
    final ext = _extensionOf(file.path);
    final path =
        '${AppConstants.storageDiscoveryPhotos}/$uid/$discoveryId$ext';
    return _uploadFile(path, file, contentType: _contentTypeFor(ext));
  }

  /// Uploads a treasure image.
  Future<String> uploadTreasureImage(String treasureId, File file) async {
    final ext = _extensionOf(file.path);
    final path = '${AppConstants.storageTreasureImages}/$treasureId$ext';
    return _uploadFile(path, file, contentType: _contentTypeFor(ext));
  }

  /// Resolves the download URL for a storage [path].
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException catch (e, st) {
      throw _mapStorage(e, st, 'Could not get the file URL.');
    }
  }

  /// Deletes a file by its storage [path] (or full gs:// / https download URL).
  Future<void> deleteFile(String pathOrUrl) async {
    try {
      final ref = pathOrUrl.startsWith('http')
          ? _storage.refFromURL(pathOrUrl)
          : _storage.ref(pathOrUrl);
      await ref.delete();
    } on FirebaseException catch (e, st) {
      // Deleting a non-existent object should be a no-op, not an error.
      if (e.code == 'object-not-found') return;
      throw _mapStorage(e, st, 'Could not delete the file.');
    }
  }

  // ===========================================================================
  // Internals
  // ===========================================================================
  Future<String> _uploadFile(
    String path,
    File file, {
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref(path);
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (e, st) {
      throw _mapStorage(e, st, 'File upload failed.');
    } catch (e, st) {
      throw MediaException('File upload failed.', cause: e, stackTrace: st);
    }
  }

  Future<String> _uploadData(
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref(path);
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (e, st) {
      throw _mapStorage(e, st, 'File upload failed.');
    } catch (e, st) {
      throw MediaException('File upload failed.', cause: e, stackTrace: st);
    }
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  AppException _mapStorage(FirebaseException e, StackTrace st, String friendly) {
    switch (e.code) {
      case 'unauthorized':
        return AuthException(
          'You do not have permission to access this file.',
          code: e.code,
          cause: e,
          stackTrace: st,
        );
      case 'canceled':
        return MediaException('Upload canceled.', code: e.code, cause: e);
      case 'retry-limit-exceeded':
        return NetworkException.timeout();
      default:
        return ServerException(friendly, code: e.code, cause: e, stackTrace: st);
    }
  }
}
