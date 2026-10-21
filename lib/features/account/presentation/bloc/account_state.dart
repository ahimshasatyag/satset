import 'package:equatable/equatable.dart';
import '../../domain/entities/user_account.dart';

class AccountState extends Equatable {
  final UserAccount? account;
  final bool isLoading;
  final bool isActionLoading;
  final bool isLoggedOut;
  final String? errorMessage;
  final String? notificationMessage;
  final String? actionSuccessMessage;

  const AccountState({
    this.account,
    this.isLoading = true,
    this.isActionLoading = false,
    this.isLoggedOut = false,
    this.errorMessage,
    this.notificationMessage,
    this.actionSuccessMessage,
  });

  AccountState copyWith({
    UserAccount? account,
    bool? isLoading,
    bool? isActionLoading,
    bool? isLoggedOut,
    String? errorMessage,
    String? notificationMessage,
    String? actionSuccessMessage,
    bool clearError = false,
    bool clearNotification = false,
    bool clearActionSuccess = false,
  }) {
    return AccountState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notificationMessage:
          clearNotification ? null : (notificationMessage ?? this.notificationMessage),
      actionSuccessMessage: clearActionSuccess
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
    );
  }

  @override
  List<Object?> get props => [
        account,
        isLoading,
        isActionLoading,
        isLoggedOut,
        errorMessage,
        notificationMessage,
        actionSuccessMessage,
      ];
}
