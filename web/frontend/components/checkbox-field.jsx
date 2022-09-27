import React, { useCallback } from 'react';
import { get } from 'lodash';
import { Checkbox } from '@shopify/polaris';

export default function CheckboxField({
  label,
  field,
  form: {
    touched,
    errors,
    setFieldValue
  },
  ...rest
}) {
  const handleChange = useCallback((newValue) => setFieldValue(field.name, newValue), []);
  return (
    <Checkbox
      label={label}
      error={get(touched, field.name) && get(errors, field.name)}
      name={field.name}
      value={field.value}
      checked={field.value}
      onChange={handleChange}
      {...rest}
    />
  )
}