import React, { useState, useCallback } from 'react';
import { get } from 'lodash';
import { TextField as Input } from '@shopify/polaris';
import { useI18n } from '@shopify/react-i18n';

export default function CurrencyField({ label, field, form: { touched, errors, setFieldValue }, ...rest }) {
  const [i18n] = useI18n();
  const [displayValue, setDisplayValue] = useState(i18n.formatCurrency(field.value, { form: 'none' }));
  const currencySymbol = i18n.getCurrencySymbol(i18n.defaultCurrency);

  const handleChange = useCallback((newValue) => {
    setDisplayValue(newValue)
    setFieldValue(field.name, i18n.unformatCurrency(newValue, i18n.defaultCurrency))
  }, []);
  const handleBlur = useCallback((event) => {
    setDisplayValue(i18n.formatCurrency(event.target.value, { form: 'none' }));
  }, []);

  return (
    <>
      <Input
        label={label}
        error={(get(touched, field.name) && get(errors, field.name))}
        value={displayValue}
        onChange={handleChange}
        onBlur={handleBlur}
        prefix={currencySymbol.prefixed && currencySymbol.symbol}
        {...rest}
      />
      <input
        type='hidden'
        onChange={handleChange}
        name={field.name}
        value={field.value}
      />
    </>
  );
}