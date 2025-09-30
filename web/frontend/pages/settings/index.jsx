import React, { useState, useCallback, useEffect } from 'react';
import {
  Badge,
  Button,
  Card,
  Form,
  FormLayout,
  Page,
  Layout,
  Stack,
  Tag,
  TextField as InputField,
} from '@shopify/polaris';
import { useToast } from '@shopify/app-bridge-react';
import { Formik, Field, FieldArray } from 'formik';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SaveBar from '../../components/save-bar';
import TextField from '../../components/text-field';
import CheckboxField from '../../components/checkbox-field';

const initialValues = {
  klaviyoPublicKey: '',
  klaviyoPrivateKey: '',
  returnPeriod: 14,
  returnExplainer: '',
  allowAutomaticPayments: true,
  cancelPrepaidCards: true,
  reauthorizePaypal: true,
  reauthorizeShopifyPayments: true,
};

export default function Settings() {
  const toast = useToast();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [tag, setTag] = useState('');
  const { isLoading, error, data } = useAppQuery({
    url: "/api/v1/shop"
  });
  const { isLoading: validationLoading, data: validation } = useAppQuery({
    url: "/api/v1/validations"
  });
  const saveMutation = useMutation(
    (shop) => fetch('/api/v1/shop', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(shop)
    }).then(async (response) => await response.json()),
    {
      onSettled: () => {
        queryClient.invalidateQueries({
          queryKey: ["/api/v1/shop", "/api/v1/validations"]
        });
      },
    }
  );
  const redirectHost = process.env.HOST;
  const themeExtensionId = import.meta.env.VITE_THEME_EXTENSION_ID;

  const onSubmit = useCallback(async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  }, [saveMutation]);

  const handleTagChange = useCallback((value) => {
    setTag(value);
  }, []);

  const handleTagAdd = useCallback(arrayHelpers => {
    arrayHelpers.push(tag);
    setTag('');
  }, [tag])

  useEffect(() => {
    if (saveMutation.isSuccess) toast.show('Save successful!', { duration: 2000 });
    if (saveMutation.isError) toast.show('Save failed!', { isError: true, duration: 2000 });
  }, [saveMutation.isSuccess, saveMutation.isError])

  if (isLoading || validationLoading) {
    return null;
  }
  
  return (
    <Page title="Settings">
      <Formik
        initialValues={{
          ...initialValues,
          ...data?.shop,
          validationEnabled: validation?.enabled,
        }}
        onSubmit={onSubmit}
      >
        {({
          handleSubmit, resetForm, submitForm, dirty, values,
        }) => (
          <Form onSubmit={handleSubmit}>
            <SaveBar dirty={dirty} submitForm={submitForm} resetForm={resetForm} />
            <Layout>
              <Layout.AnnotatedSection
                title="Rules"
                description="Add rules for your trial program."
              >
                <Card sectioned>
                  <FormLayout>
                    <Field
                      label="Enable rules"
                      name="validationEnabled"
                      component={CheckboxField}
                    />
                    
                    <Field
                      label="Max trial items per order"
                      name="maxTrialItems"
                      autoComplete="off"
                      component={TextField}
                    />
                    
                    <FieldArray name="allowedTags">
                      {arrayHelpers => (
                        <Stack vertical>
                          <InputField
                            label="Restrict trials to customers with allowed tags"
                            autoComplete="off"
                            onChange={handleTagChange}
                            value={tag}
                            verticalContent={
                              (values?.allowedTags && values?.allowedTags.length > 0) ?
                                <Stack spacing="extraTight" alignment="center">
                                  {values?.allowedTags?.map((tag, index) =>
                                    <Tag key={tag} onRemove={() => arrayHelpers.remove(index)}>{tag}</Tag>
                                  )}
                                </Stack>
                                : null
                            }
                          />
                          <Button type="button" onClick={() => handleTagAdd(arrayHelpers)}>Add Tag</Button>
                        </Stack>
                      )}
                    </FieldArray>
                  </FormLayout>
                </Card>
              </Layout.AnnotatedSection>
              <Layout.AnnotatedSection
                title="Payments"
                description="How your program handles payments from the customer."
              >
                <Card>
                  <Card.Section>
                    <FormLayout>
                      <Field
                        label="Allow automatic payments"
                        name="allowAutomaticPayments"
                        component={CheckboxField}
                      />
                      <Field
                        label={<span>Authorize new orders <Badge>Beta</Badge></span>}
                        name="authorizeTransactions"
                        component={CheckboxField}
                      />
                      <Field
                        label={<span>Cancel orders using pre-paid cards <Badge>Beta</Badge></span>}
                        name="cancelPrepaidCards"
                        component={CheckboxField}
                        helpText="Requires a checkout charge on trial plan or payment authorization"
                      />
                    </FormLayout>
                  </Card.Section>
                  <Card.Section title="Shopify Payments">
                    <Field
                      label="Re-authorize transactions"
                      name="reauthorizeShopifyPayments"
                      component={CheckboxField}
                    />
                  </Card.Section>
                  <Card.Section title="PayPal Payments">
                    <Field
                      label="Re-authorize transactions"
                      name="reauthorizePaypal"
                      component={CheckboxField}
                    />
                  </Card.Section>
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
              </Layout.AnnotatedSection>
              <Layout.Section />
            </Layout>
          </Form>
        )}
      </Formik>
    </Page>
  );
}
