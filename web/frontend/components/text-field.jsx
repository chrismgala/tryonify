import React, { useCallback } from 'react';
import { get } from 'lodash';
import { TextField as Input } from '@shopify/polaris';

export default function TextField({ label, field, form: { touched, errors, setFieldValue }, ...rest }) {
  const handleChange = useCallback((newValue) => setFieldValue(field.name, newValue), []);
  return (
    <Input
      label={label}
      error={get(touched, field.name) && get(errors, field.name)}
      {...field}
      onChange={handleChange}
      {...rest}
    />
  );
}