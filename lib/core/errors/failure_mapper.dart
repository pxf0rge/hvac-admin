import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:hvac_admin/core/errors/hvac_failure.dart';
import 'package:hvac_admin/core/errors/storage_access_exception.dart';
import 'package:hvac_admin/core/media/storage_media_validator.dart';
import 'package:hvac_admin/core/validation/billing_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps arbitrary errors to user-safe [HvacFailure] values.
abstract final class FailureMapper {
  static HvacFailure map(Object error, {StackTrace? stackTrace}) {
    if (error is HvacFailure) return error;
    if (error is BillingValidationException) {
      return ValidationFailure(error.message);
    }
    if (error is StorageMediaValidationException) {
      return ValidationFailure(error.message);
    }
    if (error is StorageAccessException) {
      return UnauthorizedFailure(error.message);
    }
    if (error is FormatException && error.message.isNotEmpty) {
      return ValidationFailure(error.message);
    }
    if (error is AuthException) {
      return _mapAuth(error);
    }
    if (error is PostgrestException) {
      return _mapPostgrest(error);
    }
    if (error is SocketException || error is TimeoutException || error is HttpException) {
      return const NetworkFailure();
    }
    if (error is ClientException) {
      return const NetworkFailure();
    }
    return UnknownFailure(_safeMessage(error));
  }

  static String messageFor(Object error) => map(error).message;

  static HvacFailure _mapAuth(AuthException error) {
    final text = error.message.toLowerCase();
    if (text.contains('invalid') || text.contains('credentials')) {
      return const ValidationFailure('Email or password is incorrect.');
    }
    return UnauthorizedFailure(error.message);
  }

  static HvacFailure _mapPostgrest(PostgrestException error) {
    final text = '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();
    if (text.contains('invalid_job_transition') || text.contains('invalid job status transition')) {
      return ValidationFailure(_trimServerMessage(error.message));
    }
    if (text.contains('job_not_found') || text.contains('job not found')) {
      return NotFoundFailure(_trimServerMessage(error.message));
    }
    if (error.code == '42501' || text.contains('permission denied') || text.contains('row-level security')) {
      return const UnauthorizedFailure('You do not have permission to perform this action.');
    }
    if (error.code == 'PGRST301' || text.contains('jwt')) {
      return const UnauthorizedFailure();
    }
    if (text.contains('insufficient stock')) {
      return ValidationFailure(_trimServerMessage(error.message));
    }
    if (error.code == '23514' || error.code == '23502' || error.code == '22P02' || error.code == '23503') {
      return ValidationFailure('Some values are invalid. Review the form and try again.');
    }
    if (error.code == 'PGRST116') {
      return const NotFoundFailure();
    }
    return ServerFailure(_trimServerMessage(error.message));
  }

  static String _trimServerMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Request could not be completed.';
    return trimmed;
  }

  static String _safeMessage(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty || text.startsWith('Exception:') || text.contains('StackTrace')) {
      return 'Something went wrong. Try again.';
    }
    return text.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
