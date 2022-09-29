import { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useContextualSaveBar } from '@shopify/app-bridge-react';

export default function SaveBar({ dirty, submitForm, resetForm }) {
  const {
    show, hide, saveAction, discardAction,
  } = useContextualSaveBar();

  useEffect(() => {
    saveAction.setOptions({
      disabled: !dirty,
      onAction: submitForm,
    });

    discardAction.setOptions({
      disabled: !dirty,
      onAction: resetForm,
    });
  }, [dirty, saveAction, discardAction, submitForm, resetForm]);

  useEffect(() => {
    if (dirty) {
      show({ fullWidth: true, leaveConfirmationDisabled: true });
    } else {
      hide();
    }

    return () => {
      hide();
    };
  });

  return null;
}

SaveBar.propTypes = {
  dirty: PropTypes.bool.isRequired,
  submitForm: PropTypes.func.isRequired,
  resetForm: PropTypes.func.isRequired,
};
