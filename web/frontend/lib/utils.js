export default function createQueryString(obj) {

  const params = new URLSearchParams();
  Object.keys(obj).forEach((key) => {
    if (obj[key]) params.append(key, obj[key]);
  });

  return params;
}