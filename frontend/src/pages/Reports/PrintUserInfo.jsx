import React, { useEffect, useState } from "react";
import {useApi} from "../../apiRequest";

export default function PrintUserInfo() {
  const [info, setInfo] = useState(null);
  const {apiRequest} = useApi()

  useEffect(() => {
    apiRequest("/info/me")
      .then(res => {
        if (res?.data?.employee) {
          setInfo(res.data.employee);
        }
      })
      .catch(() => {});
  }, []);

  if (!info) return null;

  const fullName = `${info.surname} ${info.firstname} ${info.patronymic}`;

  return (
    <div className="print-user-info">
        <strong>Дата генерации:</strong> {new Date().toLocaleDateString()} • <strong>Формат:</strong> PDF • <strong>Источник:</strong> PostgreSQL (pgx)
        <div><strong>Сотрудник:</strong> {fullName}</div>
        <div><strong>Должность:</strong> {info.position}</div>
    </div>
  );
}
