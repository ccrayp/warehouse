import styled from "styled-components";
import "bootstrap/dist/css/bootstrap.min.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import Header from "./common/Header";
import Footer from "./common/Footer";
import NotFound from "./common/NotFound";

import Home from "./pages/Home";
import { AuthProvider } from "./AuthContext";

export const ContentWrapper = styled.div`
  margin-top: 60px;
  min-height: calc(100vh - 60px);
`;

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Header />
        {/* <Sidebar />*/}
        <ContentWrapper>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </ContentWrapper>
        <Footer />
      </BrowserRouter>
    </AuthProvider>
  );
}