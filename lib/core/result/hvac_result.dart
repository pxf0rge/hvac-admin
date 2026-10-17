import 'package:hvac_admin/core/errors/hvac_failure.dart';

/// Repository / service result — prefer over throwing across layer boundaries.
sealed class HvacResult<T> {
  const HvacResult();

  bool get isSuccess => this is HvacSuccess<T>;
  bool get isFailure => this is HvacError<T>;

  T? get valueOrNull => switch (this) {
        HvacSuccess<T>(:final value) => value,
        HvacError<T>() => null,
      };

  HvacFailure? get failureOrNull => switch (this) {
        HvacSuccess<T>() => null,
        HvacError<T>(:final failure) => failure,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(HvacFailure failure) onFailure,
  }) =>
      switch (this) {
        HvacSuccess<T>(:final value) => success(value),
        HvacError<T>(:final failure) => onFailure(failure),
      };
}

final class HvacSuccess<T> extends HvacResult<T> {
  const HvacSuccess(this.value);
  final T value;
}

final class HvacError<T> extends HvacResult<T> {
  const HvacError(this.failure);
  final HvacFailure failure;
}

HvacResult<T> hvacSuccess<T>(T value) => HvacSuccess(value);

HvacResult<T> hvacError<T>(HvacFailure failure) => HvacError(failure);
