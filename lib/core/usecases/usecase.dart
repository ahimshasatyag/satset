import 'package:equatable/equatable.dart';

/// Kontrak generic untuk seluruh Use Case di layer domain
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Representasi parameter kosong saat UseCase tidak membutuhkan argumen input
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
