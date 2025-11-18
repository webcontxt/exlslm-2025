import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:dreamcast/view/speakers/controller/speakersController.dart';
import 'package:dreamcast/widgets/button/common_material_button.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api_repository/app_url.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decoration.dart';
import '../../../theme/ui_helper.dart';
import '../../../utils/dialog_constant.dart';
import '../../../utils/image_constant.dart';
import '../../../widgets/button/custom_icon_button.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../../widgets/dialog/custom_dialog_widget.dart';
import '../model/scheduleModel.dart';

class ManageSessionBookingWidget extends GetView<SessionController> {
  final SessionsData session;
  final bool isDetail;

  ManageSessionBookingWidget({
    super.key,
    required this.session,
    this.isDetail = false,
  });

  bool get _allowSeatBooking => [
        BookingType.admin_assign.name,
        BookingType.admin_approval.name,
        BookingType.auto_approval.name,
      ].contains(session.isBooking);

  bool get _isSeatAvailable => (session.availableSeats ?? 0) > 0;
  bool get _isSeatBooked => session.isSeatBooked == BookingStatus.accept.name;
  bool get _isPending => session.isSeatBooked == BookingStatus.pending.name;
  bool get _isDeclined => session.isSeatBooked == BookingStatus.decline.name;
  bool get _isApprovalBased =>
      session.isBooking == BookingType.admin_approval.name;
  bool get _isAdminAssign => session.isBooking == BookingType.admin_assign.name;
  bool get _isRevokeAllowed => session.isRevoke == true;
  bool get _canBookSeat => session.canBook == true;
  bool get _canWatchLive =>
      session.isOnlineStream == 1 && !controller.isStreaming.value;

  @override
  Widget build(BuildContext context) {
    return isDetail ? _buildDetailView(context) : _buildCompactView(context);
  }

  Widget _buildDetailView(BuildContext context) {
    if (!_allowSeatBooking || _isSeatBooked) {
      return Container(
        padding: const EdgeInsets.all(12),
        //decoration: AppDecoration.outlineBlack,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_allowSeatBooking)
              Expanded(child: _buildBookingButton(context)),
            if (_canWatchLive) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildWatchLiveButton(context)),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      //decoration: AppDecoration.outlineBlack,
      child: _buildBookingButton(context),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return SizedBox(child: _buildBookingButton(context));
  }

  Widget _buildBookingButton(BuildContext context) {
    if (!_allowSeatBooking || (_isAdminAssign && !_isSeatBooked)) {
      return const SizedBox();
    }

    String buttonText = _resolveButtonText();
    bool isDisabled = (!_isRevokeAllowed && _isSeatBooked) ||
        !_isSeatAvailable ||
        !_canBookSeat;

    final Color bgColor = _isSeatBooked
        ? (_isRevokeAllowed ? white : colorLightGray)
        : (isDisabled
            ? colorPrimary.withOpacity(0.5)
            : (_isPending || _isDeclined)
                ? _isDeclined
                    ? colorLightGray
                    : _isPending
                        ? white
                        : colorLightGray
                : colorPrimary);

    final Color textColor = _isSeatBooked
        ? colorPrimary
        : _isPending
            ? white
            : _isDeclined
                ? accentColor
                : white;
    final Color borderColor = (_isSeatBooked && _isRevokeAllowed)
        ? colorPrimary
        : _isPending
            ? Colors.transparent
            : _isDeclined
                ? Colors.transparent
                : Colors.transparent;

    return Column(
      crossAxisAlignment:
          isDetail ? CrossAxisAlignment.center : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        seatAvailableWidget(true),
        CommonMaterialButton(
          textSize: 16,
          isWrap: !isDetail,
          radius: 6,
          borderColor: borderColor,
          borderWidth: borderColor == colorPrimary ? 1 : 0,
          textColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : textColor,
          color: bgColor,
          height: isDetail ? 50 : 35.h,
          onPressed: () {
            if (!controller.authManager.isLogin()) {
              DialogConstantHelper.showLoginDialog(
                  Get.context!, controller.authManager);
              return;
            }
            _handleBooking(context);
          },
          text: buttonText,
        ),
      ],
    );
  }

  Widget seatAvailableWidget(show) {
    if ((_isSeatAvailable && !_isSeatBooked) || _isRevokeAllowed) {
      return CustomTextView(
        // text: show ? "${session.availableSeats} Seats Available" : "", /// old condition
        text: seatsAvailableTextManageWidget(),
        fontSize: 11,
        color: colorSecondary,
        fontWeight: FontWeight.w600,
      );
    }
    return const SizedBox();
  }

  String seatsAvailableTextManageWidget() {
    if (_isSeatBooked) return _isRevokeAllowed ? "" : "";
    if (_isApprovalBased) {
      if (!_canBookSeat) return "";
      if (_isPending) return _isRevokeAllowed ? "" : "";
      if (_isDeclined) return "";
      return "${session.availableSeats} Seats Available";
    }
    return _isSeatAvailable
        ? !_canBookSeat
            ? ""
            : "${session.availableSeats} Seats Available"
        : "";
  }

  String _resolveButtonText() {
    print("hello: $_isRevokeAllowed");
    if (_isSeatBooked) return _isRevokeAllowed ? "Revoke" : "Booked";

    if (_isApprovalBased) {
      if (_isPending) return _isRevokeAllowed ? "Revoke" : "Requested";
      if (_isDeclined) return "Declined";
      return "Request To Book";
    }

    return _isSeatAvailable ? "Book Now" : "Seats Full";
  }

  void _handleBooking(BuildContext context) {
    if (!_isRevokeAllowed && _isSeatBooked) {
      return;
    }

    if (!_isSeatAvailable && !_isSeatBooked) return;
    if (!_canBookSeat) return;
    if (_isApprovalBased && (_isPending && !_isRevokeAllowed || _isDeclined))
      return;

    showActionDialog(
      context: context,
      content: _isSeatBooked || _isPending
          ? "Are you sure you want to Revoke this booking request?"
          : "Are you sure you want to book this session?",
      body: {"webinar_id": session.id ?? ""},
      title: "",
      logo: _isSeatBooked || _isPending
          ? ImageConstant.icRevokeRequest
          : ImageConstant.ic_question_confirm,
      confirmButtonText: _isSeatBooked || _isPending ? "Revoke" : "Book",
    );
  }

  Widget _buildWatchLiveButton(BuildContext context) {
    return Column(
      children: [
        seatAvailableWidget(false),
        CustomIconButton(
          height: 50,
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: colorPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextView(
                  text: "watch_live".tr,
                  color: Theme.of(context).highlightColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_arrow,
                    color: Theme.of(context).highlightColor, size: 18),
              ],
            ),
          ),
          onTap: () => controller.isStreaming(!controller.isStreaming.value),
        ),
      ],
    );
  }

  void showActionDialog({
    required BuildContext context,
    required String content,
    required Map<String, dynamic> body,
    required String title,
    required String logo,
    required String confirmButtonText,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialogWidget(
          logo: logo,
          title: _isSeatBooked
              ? "Revoke"
              : (_isSeatAvailable ? "Please Confirm" : "Seats Full"),
          description: content,
          buttonAction: "Yes, $confirmButtonText",
          buttonCancel: "cancel".tr,
          onCancelTap: () {},
          onActionTap: () async {
            var result = await controller.actionAgainstSessionBooking(
              requestBody: body,
              url: _isSeatBooked || _isPending
                  ? AppUrl.revokeSessionSeat
                  : AppUrl.bookSessionSeat,
            );

            if (result["status"]) {
              await Get.dialog(
                barrierDismissible: false,
                CustomAnimatedDialogWidget(
                  title: result['title'] ?? "",
                  logo: ImageConstant.icSuccessAnimated,
                  description: result['message'],
                  buttonAction: "continue".tr,
                  buttonCancel: "cancel".tr,
                  isHideCancelBtn: true,
                  onCancelTap: () {},
                  onActionTap: () async {
                    if (isDetail) {
                      await controller.getSessionDetail(requestBody: {
                        "id": controller.mSessionDetailBody.value.id
                      });
                      controller.mSessionDetailBody.refresh();
                    }
                    controller.pullToRefresh();
                    if (Get.isRegistered<SpeakersDetailController>()) {
                      Get.find<SpeakersDetailController>()
                          .refreshTheSessionList();
                    }
                  },
                ),
              );
            } else {
              UiHelper.showFailureMsg(context, result["message"]);
            }
          },
        );
      },
    );
  }
}
