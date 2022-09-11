import React, { useCallback } from 'react';
import {
  Form,
  Page,
  Layout,
} from '@shopify/polaris';
import { Formik } from 'formik';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SaveBar from '../../components/save-bar';
import Klaviyo from '../../components/klaviyo';

const initialValues = {
  klaviyoPublicKey: '',
  klaviyoPrivateKey: '',
};

export default function Settings() {
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
      queryClient.setQueryData(['shop', response.id], response);
    },
  });

  const onSubmit = useCallback(async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  }, [saveMutation]);

  return (
    <Page title="Settings">
      <Formik
        initialValues={{
          ...initialValues,
          ...data?.shop,
        }}
        onSubmit={onSubmit}
        enableReinitialize
      >
        {({
          handleSubmit, resetForm, submitForm, dirty,
        }) => (
          <Form onSubmit={handleSubmit}>
            <SaveBar dirty={dirty} submitForm={submitForm} resetForm={resetForm} />
            <Layout>
              <Layout.AnnotatedSection
                title="Integrations"
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
