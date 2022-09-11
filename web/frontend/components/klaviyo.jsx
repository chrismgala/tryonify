import React from 'react';
import { Card, FormLayout } from '@shopify/polaris';
import { Field } from 'formik';
import TextField from './text-field';

export default function Klaviyo() {
  return (
    <Card title="Klaviyo" sectioned>
      <FormLayout>
        <Field
          label="Public Key"
          name="klaviyoPublicKey"
          component={TextField}
        />
        <Field
          label="Private Key"
          name="klaviyoPrivateKey"
          component={TextField}
          type="password"
        />
      </FormLayout>
    </Card>
  );
}
