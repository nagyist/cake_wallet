import 'package:cake_wallet/core/execution_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/monero_account_label_validator.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class MoneroAccountEditOrCreatePage extends BasePage {
  MoneroAccountEditOrCreatePage({required this.moneroAccountCreationViewModel})
      : _formKey = GlobalKey<FormState>(),
        _textController = TextEditingController() {
    _textController.addListener(() => moneroAccountCreationViewModel.label = _textController.text);
    _textController.text = moneroAccountCreationViewModel.label;
  }

  final MoneroAccountEditOrCreateViewModel moneroAccountCreationViewModel;

  @override
  String get title => S.current.account;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _textController;

  @override
  Widget body(BuildContext context) => Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: BaseTextFormField(
                    controller: _textController,
                    hintText: S.of(context).account,
                    validator: MoneroLabelValidator(),
                  ),
                ),
              ),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  onPressed: () async {
                    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                      return;
                    }

                    await moneroAccountCreationViewModel.save();

                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(_textController.text);
                    }
                  },
                  text: moneroAccountCreationViewModel.isEdit
                      ? S.of(context).rename
                      : S.of(context).add,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isLoading: moneroAccountCreationViewModel.state is IsExecutingState,
                  isDisabled: moneroAccountCreationViewModel.label?.isEmpty ?? true,
                ),
              )
            ],
          ),
        ),
      );
}
