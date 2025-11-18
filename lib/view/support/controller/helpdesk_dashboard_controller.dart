import 'package:dreamcast/view/support/controller/supportController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../main.dart';
import '../../../utils/dialog_constant.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import 'faq_controller.dart';

class HelpdeskDashboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Controller for managing tab switching
  late final TabController _tabController;
  TabController get tabController => _tabController;

  // Observable selected tab index
  final selectedTabIndex = 0.obs;

  // Tab titles for the helpdesk dashboard
  final tabList = ["FAQs", "Contact Us", "Support Chat"];

  // Dependency-injected controllers
  final SOSFaqController faqController = Get.find();
  final AuthenticationManager _manager = Get.find();

  @override
  void onInit() {
    super.onInit();
    faqController.getSOSList(isRefresh: false);
    // // Initialize TabController with the number of tabs
    // _tabController = TabController(vsync: this, length: tabList.length);
    //
    // // Add listener to handle tab changes
    // _tabController.addListener(_handleTabChange);
  }

  // Handles logic when user switches tabs
  void _handleTabChange() {
    // Ensure action is taken only when the tab index is actually changing
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;

      // Check login for "Support Chat" tab (index 2)
      if (newIndex == 2 && !_manager.isLogin()) {
        // Show login dialog if user is not logged in
        DialogConstantHelper.showLoginDialog(
          navigatorKey.currentState!.context!,
          _manager,
        );

        // Revert back to previous tab
        _tabController.index = selectedTabIndex.value;
        return;
      }

      // Update selected tab index
      selectedTabIndex.value = newIndex;

      // Perform relevant API calls or logic based on selected tab
      switch (newIndex) {
        case 0:
        // Load FAQs
          faqController.getFaqList(isRefresh: false);
          break;
        case 1:
        // Load Contact Us / SOS list
          faqController.getSOSList(isRefresh: false);
          break;
      // Case 2 (Support Chat) is gated behind login, handled above
      }
    }
  }

  // Lazy initialization of dependent controllers
  Future<void> initController() async {
    Get.lazyPut(() => SupportController(), fenix: true);
    Get.put<SOSFaqController>(SOSFaqController());
  }

  @override
  void dispose() {
    // Remove listener and dispose TabController on cleanup
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
}
