import 'package:equatable/equatable.dart';
import '../../domain/entities/user_account.dart';

class AccountState extends Equatable {
  final UserAccount? account;
  final bool isLoading;
  final bool isLoggedOut;
  final String? errorMessage;
  final String? notificationMessage;

  const AccountState({
    this.account,
    this.isLoading = true,
    this.isLoggedOut = false,
    this.errorMessage,
    this.notificationMessage,
  });

  AccountState copyWith({
    UserAccount? account,
    bool? isLoading,
    bool? isLoggedOut,
    String? errorMessage,
    String? notificationMessage,
  }) {
    return AccountState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      errorMessage: errorMessage,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [
        account,
        isLoading,
        isLoggedOut,
        errorMessage,
        notificationMessage,
      ];
}
