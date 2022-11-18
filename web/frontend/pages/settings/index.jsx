import React, { useCallback, useEffect } from 'react';
import {
  Card,
  Form,
  FormLayout,
  Page,
  Layout,
} from '@shopify/polaris';
import { useToast } from '@shopify/app-bridge-react';
import { Formik, Field } from 'formik';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SaveBar from '../../components/save-bar';
import Klaviyo from '../../components/klaviyo';
import TextField from '../../components/text-field';
import CheckboxField from '../../components/checkbox-field';

const initialValues = {
  klaviyoPublicKey: '',
  klaviyoPrivateKey: '',
  returnPeriod: 14,
  returnExplainer: '',
  allowAutomaticPayments: true,
  maxTrialItems: 3,
};

export default function Settings() {
  const toast = useToast();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const { isLoading, error, data } = useAppQuery({
    url: "/api/v1/shop"
  });
  const saveMutation = useMutation((shop) => fetch('/api/v1/shop', {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(shop)
  }).then((response) => response.data), {
    onSuccess: (response) => {
      queryClient.setQueryData("/api/v1/shop", response);
    },
  });

  const onSubmit = useCallback(async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  }, [saveMutation]);

  useEffect(() => {
    if (saveMutation.isSuccess) toast.show('Save successful!', { duration: 2000 })
  }, [saveMutation.isSuccess])

  if (isLoading) {
    return null;
  }

  return (
    <Page title="Settings">
      <Formik
        initialValues={{
          ...initialValues,
          ...data?.shop,
        }}
        onSubmit={onSubmit}
      >
        {({
          handleSubmit, resetForm, submitForm, dirty,
        }) => (
          <Form onSubmit={handleSubmit}>
            <SaveBar dirty={dirty} submitForm={submitForm} resetForm={resetForm} />
            <Layout>
              <Layout.AnnotatedSection
                title="General"
                description="Settings for general behavior of the application."
              >
                <Card sectioned>
                  <FormLayout>
                    <Field
                      label="Allow automatic payments"
                      name="allowAutomaticPayments"
                      component={CheckboxField}
                    />
                    <Field
                      label="Max trial items per order"
                      name="maxTrialItems"
                      component={TextField}
                    />
                  </FormLayout>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Returns"
                description="Customize how returns are handled for trial orders."
              >
                <Card sectioned>
                  <FormLayout>
                    <Field
                      label="Return Period (Days)"
                      name="returnPeriod"
                      component={TextField}
                      helpText="How many days customers have to complete a return before they are charged."
                    />
                    <Field
                      label="Instructions"
                      name="returnExplainer"
                      component={TextField}
                      multiline={3}
                      helpText="This text will appear above the return form when customers find their order."
                    />
                  </FormLayout>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Integrations"
                description="Connect TryOnify with other applications you use."
              >
                <Klaviyo />
              </Layout.AnnotatedSection>
            </Layout>
          </Form>
        )}
      </Formik>
    </Page>
  );
}
